# infra/ — Terraform 基礎設施

```
infra/
├── modules/
│   ├── state-backend/   # S3 state bucket + DynamoDB lock table(一次性 bootstrap)
│   ├── foundation/      # Phase 0:Budgets + SNS、Cost Anomaly Detection、CloudTrail、GitHub OIDC deploy role
│   └── serverless-app/  # Phase 1:S3+CloudFront(OAC)、HTTP API + Cognito JWT、Lambda×2、DynamoDB、SQS+DLQ
└── envs/
    ├── dev/             # 組合 foundation + serverless-app
    └── prod/            # 同結構;PITR 預設開啟、foundation 不重複建立
```

## Bootstrap 順序(第一次部署,照順序做)

State backend 有經典的雞生蛋問題:**存 state 的 S3 bucket 本身也是 Terraform 資源**,
所以它必須在沒有遠端 backend 的情況下、用本地 state 先建立一次。之後所有 env 才改用 S3 backend。

### (1) 建立 state backend(本地 state,一次性)

```bash
cd infra/modules/state-backend
terraform init
terraform apply -var="bucket_name=<你的全域唯一 bucket 名,例如 portfolio-tfstate-123456789012>"
```

記下輸出的 `bucket_name` 與 `lock_table_name`。
此目錄的本地 `terraform.tfstate` 請自行妥善保存(或之後 `terraform import` / 手動搬遷)。

### (2) 套用 dev 環境(foundation + 應用)

```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars   # 填 alert_email、github_repo、state_bucket_name

terraform init \
  -backend-config="bucket=<state bucket name>" \
  -backend-config="region=ap-northeast-1" \
  -backend-config="dynamodb_table=terraform-state-locks"

terraform apply
```

這一步會建立 foundation(Budgets $1/$5/$10 → SNS email、Cost Anomaly Detection、
CloudTrail、GitHub OIDC provider + deploy role)與完整 serverless-app stack。
**記得去信箱點 SNS 訂閱確認信**,否則告警收不到。

### (3) 設定 GitHub 變數(不是 secrets — OIDC 無金鑰)

在 repo **Settings → Secrets and variables → Actions → Variables** 建立:

| Variable | 值 |
|---|---|
| `AWS_DEPLOY_ROLE_ARN_DEV` | step (2) 輸出的 `github_deploy_role_arn` |
| `AWS_DEPLOY_ROLE_ARN_PROD` | 同帳號可重用同一 ARN;多帳號則用 prod 帳號建立的 role |
| `AWS_REGION` | 例如 `ap-northeast-1` |
| `TF_STATE_BUCKET` | state bucket 名稱 |
| `TF_LOCK_TABLE` | `terraform-state-locks`(預設值,可不設) |

### (4) push 到 main

`.github/workflows/deploy.yml` 自動執行:plan → deploy-dev → deploy-prod。
prod job 綁定 GitHub `environment: prod`,請在 **Settings → Environments → prod**
加上 Required reviewers,讓正式環境部署需要人工核准。

## 環境說明

- **dev**:`create_foundation = true`(單帳號下 foundation 只建一次)、DynamoDB PITR 關閉(免費額度姿態)。
- **prod**:`create_foundation = false`(單帳號)、PITR 開啟。Phase 3 多帳號時改為在 prod 帳號各自建 foundation。
- 所有資源經 provider `default_tags` 打上 `Project` / `Env` / `ManagedBy`。

## 常用指令

```bash
terraform fmt -recursive              # 格式化(CI 會 fmt -check)
terraform validate                    # 需先 terraform init(-backend=false 可離線驗證)
terraform output -raw cloudfront_domain_name
```
