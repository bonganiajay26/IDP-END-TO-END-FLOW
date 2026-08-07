# Backstage Developer Portal

Backstage is the developer-experience layer of this IDP. It provides the software catalog and golden paths. Terraform provisions infrastructure, GitHub Actions performs CI, and Argo CD deploys to EKS.

Create a Backstage app with `npx @backstage/create-app@latest`, then copy the catalog, template, and configuration in this directory into that generated app. Configure GitHub credentials through environment variables or, preferably in production, a GitHub App.
