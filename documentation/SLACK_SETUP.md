# Slack Webhook Setup Guide

Follow these steps to create a Slack webhook for Prometheus alerts:

## 1. Create a Slack Workspace (if you don't have one)

1. Go to https://slack.com/create
2. Follow the prompts to create a new workspace

## 2. Create an Incoming Webhook

1. Go to https://api.slack.com/apps
2. Click **"Create New App"**
3. Select **"From scratch"**
4. Enter:
   - **App Name**: `Prometheus Alerts`
   - **Workspace**: Select your workspace
5. Click **"Create App"**

## 3. Enable Incoming Webhooks

1. In the left sidebar, click **"Incoming Webhooks"**
2. Toggle **"Activate Incoming Webhooks"** to **ON**
3. Click **"Add New Webhook to Workspace"**
4. Select a channel (e.g., `#alerts` or `#general`)
5. Click **"Allow"**

## 4. Copy the Webhook URL

You'll see a webhook URL like:
```
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

**Copy this URL** - you'll need it for the Prometheus configuration.

## 5. Update Prometheus Configuration

Edit `prometheus-config/prometheus-values.yaml`:

```yaml
alertmanager:
  config:
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
```

Replace `YOUR_SLACK_WEBHOOK_URL_HERE` with the actual webhook URL you copied.

## 6. Test the Webhook (Optional)

You can test the webhook using curl:

```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test alert from Prometheus"}' \
  YOUR_WEBHOOK_URL
```

## Alternative: Use a Slack Testing Workspace

For this assignment, you can use a temporary Slack workspace:

1. Create a free Slack workspace at https://slack.com
2. Follow steps 2-4 above
3. You can delete the workspace after completing the assignment

## Slack Channel Configuration

In the Prometheus values file, you can customize:

```yaml
slack_configs:
- channel: '#alerts'        # Channel to send alerts to
  username: 'Prometheus'    # Bot username
  icon_emoji: ':prometheus:' # Bot icon
  title: 'Kubernetes Alert'
  send_resolved: true       # Send message when alert resolves
```

## Alert Format

Alerts will appear in Slack like:

```
🔔 Kubernetes Alert

Pod flask-app-xxx is down
Pod flask-app-xxx in namespace default has been down for more than 1 minute.

Severity: critical
```
