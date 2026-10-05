# ADR-0004：Phase 1 不使用 VPC（迴避 NAT Gateway 成本）

- 狀態：Accepted
- 日期：2026-09

## 背景

Lambda 可選擇是否掛進 VPC。一旦進 VPC，存取 AWS 服務（DynamoDB、SQS）與公網就需要 NAT Gateway 或 VPC endpoint。

## 決策

Phase 1（及 Phase 2）Lambda **不掛 VPC**。

## 理由

1. **成本**：NAT Gateway 單一 AZ 固定約 $32/月加流量費——是免費額度帳號最常見的超支來源（見 architecture.md §2.4）。
2. **不需要**：本架構所有依賴（DynamoDB、SQS、SNS、Cognito、CloudWatch、X-Ray）皆有公共 AWS 服務端點，Lambda 不進 VPC 即可存取，且流量走 AWS 骨幹。
3. **安全性不降**：Lambda 執行環境本身受 AWS 隔離；傳輸全程 TLS；資料層以 IAM 授權而非網路位置授權（零信任思維）。
4. **冷啟動**：不掛 VPC 省去 Hyperplane ENI 建立，冷啟動更快。

## 後果

- 未來若引入 RDS/ElastiCache 或私有第三方整合，才建立 VPC，並優先採 **VPC Gateway Endpoint**（S3/DynamoDB 免費）與 **Interface Endpoint / PrivateLink** 取代 NAT；屆時以新 ADR 記錄。
- Phase 3 的網路邊界控制改以 SCP、resource policy、endpoint policy 實現，而非預設「進 VPC 才安全」的舊思維。

## 替代方案

- 進 VPC + NAT Gateway：月費不可接受，否決。
- 進 VPC + 全 endpoint：Interface endpoint $7.2/月/個，多個服務加總仍偏高，否決。
