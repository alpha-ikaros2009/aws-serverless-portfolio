"""Generate AWS-style architecture diagrams for the serverless portfolio.

Outputs:
  - phase1-freetier.png   : Phase 1, serverless portfolio on AWS Free Tier
  - phase3-enterprise.png : Phase 3, enterprise multi-account / multi-region
"""

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib.colors import to_rgba
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

# ---------------------------------------------------------------- palette ---
INK = "#232F3E"        # AWS squid ink (main text)
SUB = "#4A5568"        # subtitle text
ZONE_EDGE = "#7A8699"  # dashed zone border
ZONE_TEXT = "#55627A"  # zone label text
ARROW = "#5A6C7D"      # default arrow
ARROW_SOFT = "#9AA5B5"  # dashed auxiliary arrow

ORANGE = "#FF9900"     # compute
BLUE = "#527FFF"       # networking / edge
GREEN = "#3F8624"      # storage / database
PURPLE = "#8C4FFF"     # security / identity
RED = "#D13212"        # observability
PINK = "#E7157B"       # messaging
SLATE = "#4A6076"      # neutral / CI-CD / accounts

OUT_DIR = __file__.rsplit("\\", 1)[0].rsplit("/", 1)[0]


# ---------------------------------------------------------------- helpers ---
def make_canvas():
    fig = plt.figure(figsize=(16, 9), dpi=200)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 9)
    ax.set_aspect("equal")
    ax.axis("off")
    fig.patch.set_facecolor("white")
    return fig, ax


def zone(ax, x, y, w, h, label, fs=10.5):
    box = FancyBboxPatch(
        (x, y), w, h,
        boxstyle="round,pad=0.02,rounding_size=0.12",
        linewidth=1.4, edgecolor=ZONE_EDGE, facecolor="none",
        linestyle=(0, (5, 4)), zorder=1,
    )
    ax.add_patch(box)
    ax.text(x + 0.18, y + h - 0.24, label, fontsize=fs, fontweight="bold",
            color=ZONE_TEXT, ha="left", va="center", zorder=2)


def node(ax, cx, cy, w, h, title, subtitle=None, color=SLATE,
         title_fs=11, sub_fs=8.5):
    box = FancyBboxPatch(
        (cx - w / 2, cy - h / 2), w, h,
        boxstyle="round,pad=0.02,rounding_size=0.09",
        linewidth=1.8, edgecolor=color,
        facecolor=to_rgba(color, 0.10), zorder=3,
    )
    ax.add_patch(box)
    if subtitle:
        ax.text(cx, cy + h * 0.18, title, fontsize=title_fs,
                fontweight="bold", color=INK, ha="center", va="center", zorder=4)
        ax.text(cx, cy - h * 0.24, subtitle, fontsize=sub_fs,
                color=SUB, ha="center", va="center", zorder=4)
    else:
        ax.text(cx, cy, title, fontsize=title_fs, fontweight="bold",
                color=INK, ha="center", va="center", zorder=4)


def arrow(ax, p1, p2, label=None, color=ARROW, rad=0.0, dashed=False,
          lw=1.6, both=False, lpos=None, lfs=8.5, lha="center"):
    a = FancyArrowPatch(
        p1, p2,
        arrowstyle="<|-|>" if both else "-|>",
        mutation_scale=14,
        connectionstyle=f"arc3,rad={rad}",
        color=color, lw=lw,
        linestyle=(0, (4, 3)) if dashed else "solid",
        shrinkA=2, shrinkB=2, zorder=5,
    )
    ax.add_patch(a)
    if label:
        if lpos is None:
            lpos = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
        ax.text(lpos[0], lpos[1], label, fontsize=lfs, color="#37455C",
                ha=lha, va="center", zorder=6,
                bbox=dict(boxstyle="round,pad=0.18", fc="white",
                          ec="none", alpha=0.9))


def title(ax, text):
    ax.text(8, 8.62, text, fontsize=20, fontweight="bold", color=INK,
            ha="center", va="center")


# ------------------------------------------------------------- diagram 1 ----
def phase1():
    fig, ax = make_canvas()
    title(ax, "Phase 1 · Serverless Portfolio on AWS Free Tier")

    # zones -----------------------------------------------------------------
    zone(ax, 0.25, 5.35, 1.90, 2.50, "Users")
    zone(ax, 2.50, 5.15, 2.65, 2.70, "Edge")
    zone(ax, 5.50, 6.25, 2.50, 1.60, "Static Hosting")
    zone(ax, 5.50, 3.40, 2.80, 2.35, "API Layer")
    zone(ax, 8.70, 3.50, 3.50, 4.35, "Compute")
    zone(ax, 12.55, 3.50, 3.20, 4.35, "Data")
    zone(ax, 0.25, 0.50, 7.75, 2.55, "CI/CD")
    zone(ax, 8.40, 0.50, 7.35, 2.55, "Observability & Cost Guardrails")

    # nodes -----------------------------------------------------------------
    node(ax, 1.20, 6.60, 1.55, 1.05, "Browser / Mobile",
         "web & mobile clients", SLATE)

    node(ax, 3.82, 7.00, 2.05, 1.00, "CloudFront",
         "CDN + HTTPS · 1TB/mo free", BLUE)
    node(ax, 3.82, 5.75, 2.05, 0.90, "Route 53",
         "custom domain · optional", BLUE)

    node(ax, 6.75, 7.00, 2.00, 0.95, "S3 Bucket",
         "static site · 5 GB free", GREEN)

    node(ax, 6.90, 4.90, 2.10, 0.95, "API Gateway",
         "HTTP API · 1M req/mo · 12 mo", BLUE)
    node(ax, 6.90, 3.90, 2.10, 0.80, "Amazon Cognito",
         "auth · ~10k MAU free", PURPLE)

    node(ax, 10.45, 6.90, 2.30, 1.00, "AWS Lambda",
         "REST API handlers", ORANGE)
    node(ax, 10.45, 4.55, 2.30, 1.00, "AWS Lambda",
         "async worker", ORANGE)
    ax.text(10.45, 3.72, "1M req + 400k GB-s always free", fontsize=8,
            style="italic", color=SUB, ha="center", va="center", zorder=4)

    node(ax, 14.15, 6.90, 2.40, 1.00, "DynamoDB",
         "25 GB always free", GREEN)
    node(ax, 14.15, 4.55, 2.40, 1.00, "SQS Queue",
         "1M req/mo free", PINK)

    node(ax, 9.90, 1.60, 2.20, 1.05, "CloudWatch",
         "10 metrics + alarms free", RED)
    node(ax, 12.25, 1.60, 1.70, 1.05, "X-Ray",
         "100k traces/mo free", RED)
    node(ax, 14.35, 1.60, 2.30, 1.05, "AWS Budgets + SNS",
         "cost alarm email", RED)

    node(ax, 1.60, 1.60, 2.30, 1.00, "GitHub Actions",
         "build · test · deploy", SLATE)
    node(ax, 4.35, 1.60, 2.30, 1.00, "IAM Deploy Role",
         "least-privilege", PURPLE)
    node(ax, 6.85, 1.60, 1.90, 1.00, "Terraform",
         "infrastructure as code", SLATE)

    # flow arrows ------------------------------------------------------------
    arrow(ax, (1.975, 6.62), (2.79, 6.92), "HTTPS", lpos=(2.38, 7.04))
    arrow(ax, (4.845, 7.00), (5.75, 7.00), "static assets", lpos=(5.30, 7.24))
    arrow(ax, (4.845, 6.72), (5.85, 5.25), "REST/HTTP API",
          rad=0.25, lpos=(5.70, 6.15))
    arrow(ax, (6.90, 4.425), (6.90, 4.30), "JWT verify",
          lpos=(7.00, 4.36), lha="left")
    arrow(ax, (7.95, 5.05), (9.30, 6.75), "invoke (REST)",
          rad=-0.18, lpos=(8.62, 6.28))
    arrow(ax, (11.60, 6.90), (12.95, 6.90), "read/write", lpos=(12.28, 7.12))
    arrow(ax, (11.55, 6.55), (13.30, 5.10), "enqueue job",
          rad=-0.12, lpos=(12.85, 5.95))
    arrow(ax, (12.95, 4.55), (11.60, 4.55), "poll & process",
          lpos=(12.28, 4.77))

    # auxiliary dashed arrows ------------------------------------------------
    arrow(ax, (3.82, 6.20), (3.82, 6.50), "DNS", dashed=True,
          color=ARROW_SOFT, lw=1.2, lpos=(4.02, 6.35), lha="left", lfs=8)
    arrow(ax, (10.30, 3.50), (10.05, 2.15), dashed=True,
          color=ARROW_SOFT, lw=1.2)
    arrow(ax, (13.90, 3.50), (12.60, 2.15), dashed=True,
          color=ARROW_SOFT, lw=1.2)
    ax.text(11.60, 2.45, "metrics · logs · traces", fontsize=8,
            color=SUB, ha="center", va="center", zorder=6,
            bbox=dict(boxstyle="round,pad=0.18", fc="white",
                      ec="none", alpha=0.9))

    # CI/CD arrows -----------------------------------------------------------
    arrow(ax, (2.75, 1.60), (3.20, 1.60), "OIDC · no stored keys",
          lpos=(2.98, 2.32))
    arrow(ax, (5.50, 1.60), (5.90, 1.60), "assume role", lpos=(5.70, 2.32))
    arrow(ax, (6.85, 2.10), (6.85, 3.30), dashed=True, color=ARROW_SOFT,
          lw=1.2)
    ax.text(6.65, 2.72, "Terraform provisions all zones", fontsize=8,
            color=SUB, ha="right", va="center", zorder=6,
            bbox=dict(boxstyle="round,pad=0.18", fc="white",
                      ec="none", alpha=0.9))

    fig.savefig(f"{OUT_DIR}/phase1-freetier.png",
                dpi=200, facecolor="white")
    plt.close(fig)


# ------------------------------------------------------------- diagram 2 ----
def phase3():
    fig, ax = make_canvas()
    title(ax, "Phase 3 · Enterprise Evolution (Multi-Account, Multi-Region)")

    # top: organizations ------------------------------------------------------
    zone(ax, 0.30, 6.30, 15.40, 1.85, "AWS Organizations / Control Tower")
    node(ax, 2.35, 7.00, 3.30, 1.05, "Management Account",
         "billing · org root · SCPs", SLATE)
    node(ax, 6.35, 7.00, 3.90, 1.05, "Security Account",
         "GuardDuty · Security Hub · CloudTrail archive", PURPLE)
    node(ax, 10.35, 7.00, 3.30, 1.05, "Shared Services Account",
         "CI/CD · DNS · artifacts", SLATE, title_fs=10.5)
    node(ax, 13.85, 7.00, 3.30, 1.05, "Workload Accounts",
         "dev · staging · prod", ORANGE)

    # route53 bar -------------------------------------------------------------
    node(ax, 5.60, 5.72, 5.20, 0.55, "Route 53 — latency / failover routing",
         None, BLUE, title_fs=10.5)

    # regions -----------------------------------------------------------------
    def region(x0, cx, label):
        zone(ax, x0, 1.25, 5.90, 4.10, label)
        node(ax, cx, 4.62, 3.40, 0.62, "CloudFront", "CDN", BLUE,
             title_fs=10.5, sub_fs=8)
        node(ax, cx, 3.87, 3.40, 0.62, "AWS WAF",
             "web ACL · managed rules", PURPLE, title_fs=10.5, sub_fs=8)
        node(ax, cx, 3.12, 3.40, 0.62, "API Gateway", "HTTP API", BLUE,
             title_fs=10.5, sub_fs=8)
        node(ax, cx, 2.37, 3.40, 0.62, "AWS Lambda", "functions", ORANGE,
             title_fs=10.5, sub_fs=8)
        node(ax, cx, 1.62, 3.40, 0.62, "DynamoDB", "global table", GREEN,
             title_fs=10.5, sub_fs=8)
        for y in (4.31, 3.56, 2.81, 2.06):
            arrow(ax, (cx, y), (cx, y - 0.13), lw=1.4)

    region(0.40, 3.35, "Region A (Primary)")
    region(6.70, 9.65, "Region B (DR / Active)")

    ax.text(5.14, 4.245, "HTTPS", fontsize=8, color="#37455C",
            ha="left", va="center", zorder=6,
            bbox=dict(boxstyle="round,pad=0.15", fc="white",
                      ec="none", alpha=0.9))

    # governance --------------------------------------------------------------
    zone(ax, 12.90, 1.25, 2.80, 4.10, "Governance")
    node(ax, 14.30, 4.75, 2.50, 0.70, "AWS Config",
         "conformance packs", RED, title_fs=10.5, sub_fs=8)
    node(ax, 14.30, 3.85, 2.50, 0.70, "Centralized Logging",
         "S3 log archive", GREEN, title_fs=10.5, sub_fs=8)
    node(ax, 14.30, 2.95, 2.50, 0.70, "KMS",
         "encryption keys", PURPLE, title_fs=10.5, sub_fs=8)
    node(ax, 14.30, 2.05, 2.50, 0.70, "Cost Anomaly Detection",
         "spend alerts", "#B8470F", title_fs=10, sub_fs=8)

    # cross-region / cross-zone arrows ---------------------------------------
    arrow(ax, (4.40, 5.39), (3.60, 4.95), "latency", rad=0.18,
          lpos=(3.95, 5.33), lfs=8)
    arrow(ax, (7.00, 5.39), (9.40, 4.95), "failover", rad=-0.18,
          lpos=(8.45, 5.33), lfs=8)

    arrow(ax, (5.05, 1.62), (7.95, 1.62), both=True, color=GREEN, lw=1.8,
          label="bi-directional replication (global tables)",
          lpos=(6.50, 1.90), lfs=8)

    arrow(ax, (10.35, 6.475), (10.35, 5.45), dashed=True, color=ARROW_SOFT,
          lw=1.3, label="SCPs · guardrails · account vending",
          lpos=(10.52, 5.95), lha="left", lfs=8)

    arrow(ax, (11.35, 2.55), (13.05, 2.75), dashed=True, color=ARROW_SOFT,
          lw=1.2, label="logs · config · keys", lpos=(12.15, 2.92), lfs=8)

    fig.savefig(f"{OUT_DIR}/phase3-enterprise.png",
                dpi=200, facecolor="white")
    plt.close(fig)


if __name__ == "__main__":
    phase1()
    phase3()
    print("done")
