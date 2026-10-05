# ADR-0003：IaC 採 Terraform，CI/CD 採 GitHub Actions + OIDC（無長期金鑰）

- 狀態：Accepted
- 日期：2026-09

## 背景

需要選定 IaC 工具與部署管線，並決定 CI 系統如何取得 AWS 授權。

## 決策

- IaC：**Terraform**（module 化結構：`infra/modules/` + `infra/envs/{dev,prod}`）
- CI/CD：**GitHub Actions**，透過 **IAM OIDC Provider + Deploy Role** 取得短期憑證

## 理由

1. **Terraform**：職缺市場需求最高的 IaC 工具；module 介面可直接支撐 Phase 3 的多環境、多帳戶、多 region（同一 module 套不同 provider/變數），符合「演進不重寫」原則。
2. **OIDC 取代 Access Key**：GitHub Actions 以 OIDC token 向 AWS STS 換取短期憑證，role trust policy 限定特定 repo 與 branch——**倉庫與 AWS 帳號中都不存在長期金鑰**，消除金鑰外洩這一最常見的雲端事故來源。
3. **GitHub Actions**：public repo 免費；原生整合 PR 流程（PR → `terraform plan` 留言，merge → `apply`）。
4. State 放 S3 backend（版本控制 + 加密）+ DynamoDB lock table，兩者都在免費額度內。

## 後果

- Deploy role 需細緻拆分權限（最小權限），初期建置成本較高，但本身就是作品集亮點。
- 若日後遷移至多帳戶，CI 需改為 role chaining（Shared Services 帳戶 → workload 帳戶 deploy role），OIDC 模式不變。

## 替代方案

- AWS CDK / SAM：開發體驗佳，但 Terraform 在多雲與職缺市場的通用性更高；保留為未來 ADR 重新評估。
- CloudFormation：免費但模板冗長、抽象層薄，否決。
- 存 IAM User Access Key 於 GitHub Secrets：違反安全預設，否決。
