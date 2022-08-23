
# trust event bridge to use this role
resource "aws_iam_role" "sh_event_bus_invoke_remote_event_bus" {
  name               = "${var.name_prefix}reporting-sh-event-bus-forward-to-admin-event-bus"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "events.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
    }
  EOF
}

# allow to push events to another bus
data "aws_iam_policy_document" "sh_event_bus_invoke_remote_event_bus_document" {
  statement {
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.admin_events_bus_arn]
  }
}

resource "aws_iam_policy" "sh_event_bus_invoke_remote_event_bus_policy" {
  name   = "event_bus_invoke_remote_event_bus"
  policy = data.aws_iam_policy_document.sh_event_bus_invoke_remote_event_bus_document.json
}

resource "aws_iam_role_policy_attachment" "sh_event_bus_invoke_remote_event_bus" {
  role       = aws_iam_role.sh_event_bus_invoke_remote_event_bus.name
  policy_arn = aws_iam_policy.sh_event_bus_invoke_remote_event_bus_policy.arn
}


resource "aws_cloudwatch_event_rule" "sh_forward_events_to_admin_rule" {
  name        = "${var.name_prefix}reporting-capture-security-hub-findings-events"
  description = "Capture Security Hub findings events and forward them to OU admin account event bus"
  tags        = var.custom_tags

  event_pattern = <<-EOF
    {
      "source": ["aws.securityhub"],
      "detail-type": ["Security Hub Findings - Imported"]
    }
  EOF
}


resource "aws_cloudwatch_event_target" "sh_events_to_admin_bus" {
  target_id      = "${var.name_prefix}reporting-admin-account-event-bus"
  event_bus_name = aws_cloudwatch_event_rule.sh_forward_events_to_admin_rule.event_bus_name
  rule           = aws_cloudwatch_event_rule.sh_forward_events_to_admin_rule.name
  arn            = var.admin_events_bus_arn
  role_arn       = aws_iam_role.sh_event_bus_invoke_remote_event_bus.arn
}
