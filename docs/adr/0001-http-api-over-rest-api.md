# ADR-0001：API Gateway 選用 HTTP API（v2）而非 REST API（v1）

- 狀態：Accepted
- 日期：2026-09

## 背景

API 層需要在 API Gateway 的 REST API（v1）與 HTTP API（v2）之間選擇。

## 決策

採用 **HTTP API（v2）**。

## 理由

1. **成本**：HTTP API 定價約為 REST API 的 1/3（$1.00 vs $3.50 每百萬次，超過免費額度後），符合本專案的成本紀律。
2. **延遲**：HTTP API 開銷較小，p99 延遲更低。
3. **內建 JWT Authorizer**：直接向 Cognito（或任何 OIDC issuer）驗發 JWT，驗證邏輯不用進 Lambda——更便宜也更安全。
4. **本階段用不到 REST API 獨有功能**：API key/usage plan、request validation、edge-optimized endpoint、WAF 直接綁定等，Phase 1 皆不需要。

## 後果

- 若未來需要 usage plan（第三方 API 商業化）或 API 層 WAF，需遷回 REST API 或將防護上移 CloudFront（WAF on CloudFront 已涵蓋大部分場景）。
- OpenAPI 匯入定義在兩者間相容度高，遷移成本可控。

## 替代方案

- REST API：功能全但貴、慢；否決。
- Lambda Function URL：免費但無授權層、無自訂網域彈性；僅適合 demo，否決。
- App Runner / ALB：持續計費，違反零閒置原則，否決。
