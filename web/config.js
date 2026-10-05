// Runtime config injected at deploy time by .github/workflows/deploy.yml
// (sed replaces __API_BASE_URL__ with https://<cloudfront-domain>/api).
// Locally / before injection the placeholder stays and the page falls back
// to same-origin /api with graceful degradation.
window.API_BASE_URL = "__API_BASE_URL__";
