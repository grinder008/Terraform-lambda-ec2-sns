# AWS Event-Driven Automation

This project demonstrates an event-driven AWS workflow using CloudTrail, EventBridge, Lambda, and SNS. When a specific AWS API action occurs (such as an S3 bucket deletion), CloudTrail records the event, EventBridge captures it, Lambda processes it, and SNS sends an email notification.

## Architecture

CloudTrail → EventBridge → Lambda → SNS → Email

## Services Used

- AWS CloudTrail
- Amazon EventBridge
- AWS Lambda
- Amazon SNS
- IAM

## Learning Outcomes

- Event-driven architectures
- AWS monitoring and auditing
- Lambda automation with Python
- SNS notifications
- IAM permissions management

## Author

**Riadh Karaoud**
