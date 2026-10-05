# ADR-0002：DynamoDB 採 on-demand 計費 + 單表設計

- 狀態：Accepted
- 日期：2026-09

## 背景

主資料庫需要在 DynamoDB（provisioned / on-demand）、RDS/Aurora Serverless、S3-based 方案間選擇；若選 DynamoDB，還需決定資料建模方式。

## 決策

採用 **DynamoDB on-demand**，並以**單表設計（single-table design）**建模。

## 理由

1. **零閒置成本**：on-demand 無流量即 $0；25 GB 儲存屬 Always Free。Aurora Serverless v2 最低 0.5 ACU 仍有持續計費，違反零閒置原則。
2. **演進紅利**：Phase 3 的多區域 DR 由 **DynamoDB Global Tables** 直接提供（雙寫雙活），資料庫不用換——這是本架構「免費版一路長到企業版」論證的關鍵支柱。
3. **單表設計**：以 PK/SK + GSI 在同一張表內建模多實體（project / visitor / message），減少 RCU 浪費與跨表 join，也是 enterprise 級 DynamoDB 的主流實踐，提前在作品集中展示建模能力。
4. **效能**：單位數毫秒延遲，與 Lambda 組合後 API p99 容易達到 < 300ms 的 SLO。

## 後果

- 單表設計學習曲線較陡；需在建模前先列出所有 access pattern（寫入設計註解）。
- 複雜 ad-hoc 查詢不在 DynamoDB 做；若未來需要分析，走 DynamoDB → S3 export → Athena，而非引入 RDS。

## 替代方案

- Provisioned 模式：可精準壓在 25 RCU/WCU 免費額度，但流量成長需手動調整；on-demand 在免費額度內同樣免費且零維運，否決。
- Aurora Serverless v2：關聯式能力強但有最低計費與 VPC 需求（連帶 NAT 成本），否決。
