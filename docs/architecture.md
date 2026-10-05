# 架構設計文件：免費額度 Serverless → 企業級演進方案

> 版本：v1.0 ｜ 日期：2026-09 ｜ 狀態：設計定稿
> 所有免費額度數字以撰寫當下為準，部署前務必至 <https://aws.amazon.com/free/> 重新核對。

---

## 1. 設計目標與原則

| 目標 | 說明 |
|---|---|
| **零成本起步** | Phase 0–1 完全落在 Always Free 額度內，目標月費 $0 |
| **可演進，不重寫** | 每一層的服務選型在企業階段「同一服務繼續長大」，而非換掉重來 |
| **安全預設（Secure by default）** | 無長期金鑰、最小權限 IAM、全站 HTTPS、加密 at rest |
| **成本可觀測** | 第一行 Terraform 就建立 Budget 告警與異常偵測 |
| **Everything as Code** | 基礎設施（Terraform）、流程（GitHub Actions）、決策（ADR）全部進版控 |

核心判斷：**Serverless 服務本身（Lambda / API Gateway / DynamoDB / SQS / EventBridge）天生就是從免費額度一路长到企業級的同一條路**。企業化真正要加的不是換服務，而是：多帳戶治理、網路邊界、合規、DR、FinOps。這份文件把這條路徑寫死，避免日後「免費版寫法」變成技術債。

---

## 2. 免費額度盤點（Free Tier Budget）

### 2.1 2025 年後的新制（重要）

AWS 自 2025 年 7 月起對**新帳號**改用點數制：

- 新帳號立即獲得 **$100 點數**，完成指定任務最多再拿 $100（共 $200）
- **Free plan**：限用部分服務、最長 6 個月，點數用完或到期帳號自動關閉，不會產生帳單
- **Paid plan**：按量計費，超過 Always Free 額度先扣點數
- **Always Free**：30+ 服務在兩種 plan 下都有每月免費額度，不設期限

**策略結論**：本架構以 Always Free 服務為骨幹，因此無論帳號適用新舊制都能跑；12 個月制項目（S3、CloudFront、API Gateway）到期後成本也極低（見 §2.3）。

### 2.2 本架構用到的額度對照表

| 服務 | 用途 | 免費額度（每月） | 額度類別 |
|---|---|---|---|
| AWS Lambda | API handler + async worker | 100 萬次請求 + 400,000 GB-秒 | **Always Free** |
| Amazon DynamoDB | 主資料庫（on-demand） | 25 GB 儲存 + 25 RCU / 25 WCU（另含每月免費請求量） | **Always Free** |
| Amazon SQS | 非同步佇列 + DLQ | 100 萬次請求 | **Always Free** |
| Amazon SNS | 成本告警通知 | 100 萬次發布 | **Always Free** |
| Amazon Cognito | 使用者認證 | 約 10,000 MAU（Lite 層） | **Always Free**（新計費制下） |
| Amazon CloudWatch | 日誌 / 指標 / 告警 | 10 自訂指標 + 10 告警 + 5 GB 日誌 | **Always Free**（基本額度） |
| AWS X-Ray | 分散式追蹤 | 100,000 條 trace | **Always Free** |
| AWS Budgets | 預算告警 | 前 2 個 budget 免費 | **Always Free** |
| AWS Cost Anomaly Detection | 異常花費偵測 | 免費 | **Always Free** |
| AWS CloudFormation | Terraform 之外的選項 | AWS:: 資源免費 | **Always Free** |
| Amazon API Gateway | HTTP API | 100 萬次呼叫 | **12 個月** |
| Amazon S3 | 靜態網站 + artifact | 5 GB 標準儲存、20k GET / 2k PUT | **12 個月** |
| Amazon CloudFront | CDN + HTTPS 終端 | 1 TB 傳出 + 1,000 萬次請求 | 依官網當期政策（近年起為長期額度，部署前核對） |
| GitHub Actions | CI/CD | Public repo 免費無限 | 第三方，非 AWS |

### 2.3 免費期過後的真實成本（作品集流量級）

以低流量作品集（每月 ~5 萬次 API 呼叫、~10 GB CDN 流量）估算：

| 項目 | 估算月費 |
|---|---|
| Lambda / DynamoDB / SQS | $0（仍在 Always Free 內） |
| API Gateway HTTP API | < $0.10 |
| CloudFront 10 GB | ~$0.90 |
| S3 5 GB | ~$0.12 |
| Route 53 hosted zone（Phase 2 自訂網域才加） | $0.50 |
| **合計** | **< $2 / 月** |

### 2.4 成本地雷清單（作品集帳號最常見的超支來源）

| 地雷 | 月費 | 本架構的迴避方式 |
|---|---|---|
| NAT Gateway | ~$32 + 流量費 | **Phase 1 不使用 VPC**；Lambda 呼叫 AWS 服務走公共端點 |
| 未釋放的 Elastic IP | ~$3.6/個 | 不建 EC2、不建 NAT 就沒有 EIP |
| KMS 自訂 CMK | $1/把 | Phase 1 用 AWS managed key（免費）；Phase 3 才導入 CMK |
| Secrets Manager | $0.40/secret | Phase 1 無第三方 secret；Cognito token 由前端處理 |
| Provisioned Concurrency | 持續計費 | 只用 on-demand；冷啟動用 SnapStart（Java）或精簡部署包 |
| CloudWatch Logs 無限保留 | 累積計費 | 所有 log group 設 14–30 天 retention |
| Route 53 hosted zone | $0.50/個 | Phase 1 先用 `*.cloudfront.net`，Phase 2 才買網域 |
| 忘記關的實驗資源 | 不定 | Budget 告警 + 每週 Cost Explorer 檢查 + tag 全部資源 |

---

## 3. Phase 0：帳號地基（第 0 天，建任何東西之前）

1. **Root 帳號**：啟用 MFA（硬體金鑰或 TOTP），之後不再使用 root。
2. **IAM Identity Center**：建立管理用 IAM 使用者，日常操作不走 root。
3. **成本防線（第一批 Terraform 資源）**：
   - AWS Budgets：$1 / $5 / $10 三階告警 → SNS → Email
   - Cost Anomaly Detection：監控全部服務，異常即通知
   - Cost Explorer 啟用；資源一律打 tag（`Project`, `Env`, `Owner`）
4. **CloudTrail**：啟用管理事件紀錄（90 天內查詢免費）。
5. **部署身分**：建立 GitHub Actions 專用的 IAM OIDC Provider + Deploy Role（最小權限、限定 repo/branch），**不存任何 AWS Access Key 在 GitHub Secrets**。
6. **Terraform state**：S3 backend（版本控制 + 加密）+ DynamoDB lock table——這兩個資源本身也在免費額度內。

---

## 4. Phase 1：免費額度 Serverless MVP

![Phase 1](../diagrams/phase1-freetier.png)

### 4.1 請求路徑

1. 瀏覽器 → **CloudFront**（HTTPS、HTTP/2、OAC 簽署）→ **S3** 拿靜態網站。
2. 瀏覽器 → CloudFront `/api/*` 行為 → **API Gateway HTTP API**。
3. 受保護路由由 API Gateway 的 **JWT Authorizer** 直接向 **Cognito** 驗證，Lambda 不碰驗證邏輯。
4. **Lambda（REST handlers）** 讀寫 **DynamoDB**（單表設計，on-demand）。
5. 聯絡表單等慢工作：API Lambda → **SQS** → **worker Lambda** 非同步處理；失敗進 **DLQ**。
6. 全部服務 → **CloudWatch**（結構化日誌 + 告警）與 **X-Ray**（追蹤）。
7. **GitHub Actions** 以 OIDC assume deploy role → **Terraform** 部署所有資源。

### 4.2 關鍵設計決策（詳見 docs/adr/）

| # | 決策 | 理由 |
|---|---|---|
| ADR-0001 | HTTP API（v2）而非 REST API | 延遲更低、價格低約 70%、內建 JWT authorizer；REST API 的進階功能本階段用不到 |
| ADR-0002 | DynamoDB on-demand + 單表設計 | 零閒置成本；流量成長不用改架構；單表設計提前練習 enterprise 級建模 |
| ADR-0003 | Terraform + GitHub Actions OIDC | 業界需求最高的 IaC 組合；無長期金鑰；module 結構直接支撐多環境 |
| ADR-0004 | 不進 VPC | NAT Gateway 是免費帳號最大地雷；DynamoDB/SQS 都有公共端點，Lambda 不需要 VPC |

### 4.3 這個階段展示的架構師能力（面試談資）

- 免費額度的精確計算與成本護欄設計（§2）
- Well-Architected 六大支柱逐一對應的取捨說明
- 單表設計、JWT 授權、非同步解耦、DLQ 重試語意
- OIDC 無金鑰 CI/CD、IaC module 化

---

## 5. Phase 2：成長期（月費 ~$1–10，自訂網域與多環境）

| 改動 | 成本 | 說明 |
|---|---|---|
| Route 53 hosted zone + ACM 憑證 | $0.50/月（憑證免費） | 自訂網域 `api.example.com`、A/AAAA alias 到 CloudFront |
| 環境分離：dev / prod | ~$0 | Terraform workspace 或 `envs/` 目錄；PR 觸發 plan，merge 才 apply prod |
| PR preview 環境 | ~$0 | 每個 PR 建 ephemeral stack，關 PR 自動銷毀（展現平台思維） |
| AWS WAF on CloudFront | ~$5–8/月 | 受管規則組（AWSManagedRulesCommonRuleSet）；可延後到真實流量再上 |
| CloudWatch RUM + 自訂指標 | 低 | 前端真實使用者效能監控 |
| DynamoDB PITR 備份 | 低 | 35 天連續備份，誤刪可還原 |
| Lambda 部署優化 | $0 | esbuild 打包、arm64（Graviton，便宜 ~20%）、SnapStart（若用 Java） |

此階段的重點是**工程流程企業化**：環境提升（promotion）、回滾策略（terraform apply 前一版 state / Lambda alias + codedeploy 金絲雀）、變更審核。

---

## 6. Phase 3：企業級演進

![Phase 3](../diagrams/phase3-enterprise.png)

### 6.1 多帳戶治理（AWS Organizations + Control Tower）

| 帳戶 | 職責 |
|---|---|
| Management | 帳單、Org root、SCP；不放任何 workload |
| Security / Log Archive | GuardDuty 聚合、Security Hub、CloudTrail 不可變日誌歸檔（S3 Object Lock） |
| Shared Services | CI/CD 工具、DNS、artifact registry（ECR/S3） |
| Workload（dev / staging / prod） | 實際應用，帳戶即最強隔離邊界 |

- **SCP** 範例：禁用未核准 region、禁止關閉 CloudTrail、強制加密。
- 帳戶開設用 **Account Factory** / IaC 自動化（account vending）。

### 6.2 多區域與災難復原

- **Route 53** latency / failover routing 指向兩個 region。
- **DynamoDB Global Tables**：雙寫雙活，RPO 趨近 0、RTO 分鐘級；這正是 Phase 1 選 DynamoDB 的紅利——不用換資料庫。
- 前端與 API 層為無狀態，region B 平時可用最小容量（pilot light）或直接 active-active。
- IaC 保證兩邊一致：同一組 Terraform module 套兩個 region provider。

### 6.3 安全與合規

- **WAF** 受管規則 + rate limiting（per-IP）擋在 CloudFront。
- **KMS CMK**（含 key rotation）取代 AWS managed key，加密 DynamoDB / SQS / S3 / Logs。
- **AWS Config + conformance packs**：持續合規檢查（如 PCI / 自訂基準）。
- **Security Hub 標準**（FSBP / CIS）+ **GuardDuty** 威脅偵測，事件彙入 Security 帳戶。
- Secrets 需求出現時導入 Secrets Manager + rotation（此時 $0.40/secret 已合理）。
- 私有整合（如 RDS、第三方內網）才引入 VPC + PrivateLink／VPC endpoint——**按需引入，不預設付 NAT 的錢**。

### 6.4 可觀測性與可靠性工程

- 日誌統一送至 Log Archive 帳戶（S3 + 生命週期轉 Glacier）。
- 定義 **SLO/SLI**（如 API p99 < 300ms、可用性 99.9%），CloudWatch 複合告警 + error budget。
- 金絲雀部署（Lambda alias 權重）、自動回滾。
- GameDay / 故障注入（AWS FIS）驗證 DR。

### 6.5 FinOps

- Cost and Usage Report（CUR）→ S3 → Athena 查詢單位經濟（如「每次 API 呼叫成本」）。
- Tag 策略強制化（SCP 拒絕無 tag 建資源）。
- 定期 Well-Architected Review + Trusted Advisor。

### 6.6 演進路徑的「不變量」

從 Phase 1 到 Phase 3，以下**完全不需要改寫**，這是本方案的核心論證：

- API 合約（OpenAPI spec）與 Lambda handler 程式碼
- DynamoDB 資料模型（global tables 是設定，不是改架構）
- 非同步流程（SQS/EventBridge 語意不變）
- Terraform module 介面（同一份 module，從單帳戶單 region 套到多帳戶多 region）
- CI/CD 管線形狀（只是多了帳戶與環境矩陣）

---

## 7. Well-Architected 對照

| 支柱 | 本架構的落點 |
|---|---|
| Operational Excellence | 全 IaC、ADR、PR plan/apply、runbook |
| Security | OIDC 無金鑰、最小權限、OAC、JWT authorizer、SCP/WAF/KMS（Phase 3） |
| Reliability | 全託管無伺服器、DLQ 重試、multi-region global tables（Phase 3） |
| Performance Efficiency | arm64 Lambda、CDN 快取、DynamoDB 單位數毫秒延遲 |
| Cost Optimization | Always Free 組合、on-demand 計費、Budgets + 異常偵測 |
| Sustainability | Serverless 按需運算、arm64、無閒置資源 |

---

## 8. 後續實作順序（建議）

1. `infra/`：Terraform backend、budgets、OIDC role（Phase 0 → 可先獨立 commit）
2. `services/api` + `services/worker`：最小 API（GET /health、訪客計數、聯絡表單）
3. GitHub Actions：CI（lint/test）→ deploy（OIDC + terraform）
4. `web/`：靜態作品集頁面，串 API
5. README 補上實際部署截圖、成本截圖（$0 帳單是最好的作品集素材）
6. Phase 2/3 以 issue + ADR 形式逐步落地
