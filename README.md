# tofu-github-playground

A hands-on demo of managing GitHub repositories with **OpenTofu + GitHub Actions**, using **AWS S3** for remote state.

Everything is managed as code in `infra/`: repository settings, branches, rulesets, Actions permissions, secrets, OIDC roles, and the state bucket.

**🔑 Only manual setup required:** adding the GitHub Personal Access Token (`GH_PAT`) as a repository secret. Everything else is provisioned by OpenTofu.

## ⚙️ How it works

```mermaid
flowchart TD
    PR["🔀 PR to main<br/>infra/**"] --> PLAN["🧪 tofu-plan.yaml"]
    PLAN --> PRROLE["🔐 PR IAM role<br/>Read state + lock"]
    PRROLE --> COMMENT["💬 Plan comment"]

    PUSH["🚀 Push to main<br/>infra/**"] --> APPLY["📦 tofu-apply.yaml"]
    APPLY --> MAINROLE["🔐 Main IAM role<br/>Write state + resources"]

    PRROLE & MAINROLE --> OIDC["AWS via GitHub OIDC<br/>No static AWS keys"]
```
