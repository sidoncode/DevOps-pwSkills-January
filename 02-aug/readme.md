# AWS SQS + Lambda - Complete All-in-One Guide

**Everything you need to understand and build serverless message processing with AWS SQS and Lambda**

---

## Table of Contents

1. [Part 1: Beginner Concepts](#part-1-beginner-concepts)
2. [Part 2: How It Works](#part-2-how-it-works)
3. [Part 3: AWS Console Setup](#part-3-aws-console-setup)
4. [Part 4: Lambda Code Examples](#part-4-lambda-code-examples)
5. [Part 5: Advanced Topics](#part-5-advanced-topics)
6. [Part 6: Monitoring & Troubleshooting](#part-6-monitoring--troubleshooting)
7. [Part 7: Production Deployment](#part-7-production-deployment)
8. [Part 8: Best Practices](#part-8-best-practices)

---

# PART 1: BEGINNER CONCEPTS

## What is This?

**Simple Answer:** Lambda automatically triggers when messages arrive in an SQS queue.

Think of it like a **bell connected to a mailbox:**
- **Mailbox** = SQS Queue (holds messages)
- **Bell** = Trigger (rings when mail arrives)
- **You** = Lambda Function (wakes up when bell rings)

When a letter arrives → Bell rings → You wake up → You read it

## The Three Main Things

### 1. SQS (Simple Queue Service)
- **What:** Managed message queue in AWS
- **Job:** Receives and stores messages
- **Why:** Decouples your applications
- **Cost:** $0.40 per million requests

### 2. Lambda (Serverless Function)
- **What:** Code that runs automatically
- **Job:** Processes messages when they arrive
- **Why:** No servers to manage, scales automatically
- **Cost:** $0.20 per million invocations + execution time

### 3. Trigger (Event Source Mapping)
- **What:** Connection between SQS and Lambda
- **Job:** Tells Lambda "wake up, new message!"
- **Why:** Makes Lambda respond automatically
- **How:** AWS handles it automatically

## The Flow

```
┌─────────────┐
│  Your App   │
│  Sends Msg  │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│   SQS Queue      │
│ (Holds Messages) │
└──────┬───────────┘
       │ "New message!"
       │ (Automatic)
       ▼
┌──────────────────────────┐
│  Lambda Function         │
│  ✓ Wakes up             │
│  ✓ Reads message        │
│  ✓ Processes it         │
│  ✓ Deletes it           │
└──────────────────────────┘
```

## Why Use This?

✅ **No Servers** - AWS manages everything
✅ **Automatic Scaling** - Handles 1 or 1 million messages
✅ **Pay Per Use** - Only pay when messages arrive
✅ **No Polling** - Lambda triggers automatically
✅ **Reliable** - Built-in error handling & retries
✅ **Simple** - Easy to set up and understand

## Real-World Use Cases

- **E-commerce:** Order processing
- **Media:** Image resizing after upload
- **Notifications:** Send emails automatically
- **Data:** Transform and move data
- **Integrations:** Connect multiple services
- **Background Jobs:** Cleanup, reports, etc.

---

# PART 2: HOW IT WORKS

## Simple Example

### What Happens When You Send a Message

**Step 1:** Your Python script sends message
```python
import boto3
sqs = boto3.client('sqs')
sqs.send_message(
    QueueUrl='https://sqs.us-east-1.amazonaws.com/123456789/my-queue',
    MessageBody='Hello Lambda!'
)
```

**Step 2:** Message arrives in SQS Queue
```
Queue Status: 1 message waiting
```

**Step 3:** SQS notifies Lambda automatically
```
AWS: "Lambda, wake up! New message in queue!"
```

**Step 4:** Lambda wakes up and runs
```python
def lambda_handler(event, context):
    for message in event['Records']:
        print(f"Got message: {message['body']}")
    return 'Done!'
```

**Step 5:** Lambda output
```
Got message: Hello Lambda!
```

**Step 6:** Message deleted from queue
```
Queue Status: 0 messages (cleaned up automatically)
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Your Application / Python Script                      │
│  (Sends messages with boto3)                           │
│                                                         │
└───────────────┬─────────────────────────────────────────┘
                │
                │ boto3.sqs.send_message()
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  AWS SQS Queue                                          │
│  ├─ Queue Name: my-simple-queue                        │
│  ├─ Type: Standard or FIFO                             │
│  ├─ Status: Holds messages                             │
│  └─ Dead Letter Queue (for failures)                   │
│                                                         │
└───────────────┬─────────────────────────────────────────┘
                │
                │ Automatic Event Source Mapping
                │ (AWS handles this)
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  AWS Lambda Function                                   │
│  ├─ Name: simple-processor                             │
│  ├─ Runtime: Python 3.11                               │
│  ├─ Trigger: SQS (10 messages at a time)               │
│  └─ Auto-scales based on queue depth                   │
│                                                         │
│  def lambda_handler(event, context):                   │
│      process_messages(event)                           │
│      return success                                    │
│                                                         │
└───────────────┬─────────────────────────────────────────┘
                │
        ┌───────┴────────┬──────────┬──────────┐
        │                │          │          │
        ▼                ▼          ▼          ▼
    Database         S3 Storage   SNS Email   External API
   (DynamoDB)      (Save files) (Notify)    (Call service)

```

## Message Structure

When Lambda receives a message, here's what it looks like:

```python
{
    "Records": [
        {
            "messageId": "abc123def456",
            "receiptHandle": "AQEB...",
            "body": "Hello Lambda!",
            "messageAttributes": {
                "priority": {
                    "stringValue": "high",
                    "dataType": "String"
                }
            },
            "md5OfBody": "...",
            "eventSource": "aws:sqs",
            "eventSourceARN": "arn:aws:sqs:us-east-1:123456789:my-queue",
            "awsRegion": "us-east-1"
        }
    ]
}
```

Lambda processes each message in the `Records` array.

## Batch Processing

**What:** Lambda processes multiple messages in one invocation

**Example:**
- Queue has 25 messages
- Batch size = 10
- Lambda invoked 3 times (10, 10, 5 messages)

**Benefits:**
- Faster processing
- Lower costs
- Better efficiency

---

# PART 3: AWS CONSOLE SETUP

## Prerequisites

### 1. AWS Account
- Create at https://aws.amazon.com
- Free tier available

### 2. AWS Console Access
- Log in to https://console.aws.amazon.com
- Have your credentials ready

### 3. Permissions
- You need permissions to create SQS queues
- You need permissions to create Lambda functions
- (Free tier has these permissions)

## STEP 1: Create SQS Queue (5 minutes)

### Action 1.1: Navigate to SQS

```
1. Go to AWS Console
2. Search for "SQS" (top left search bar)
3. Click "Simple Queue Service"
```

**You should see:**
```
SQS Dashboard
├─ Create queue (orange button)
└─ Queues (empty list)
```

### Action 1.2: Create Queue

**Click "Create queue"**

Fill in the form:
```
Queue name:     my-simple-queue
Queue type:     Standard ✓ (recommended)
```

Scroll down and click **"Create queue"**

**Result:**
```
✓ Queue created!
Queue URL: https://sqs.us-east-1.amazonaws.com/123456789/my-simple-queue
```

### Action 1.3: Copy Queue URL

**Important:** Copy this URL somewhere safe (notepad, etc.)

```
https://sqs.us-east-1.amazonaws.com/123456789/my-simple-queue
                                      ↑
                              Your Account ID
```

You'll need this URL for:
- Lambda configuration
- Python scripts
- Testing

---

## STEP 2: Create Lambda Function (5 minutes)

### Action 2.1: Navigate to Lambda

```
1. Go to AWS Console
2. Search for "Lambda"
3. Click "AWS Lambda"
```

**You should see:**
```
Lambda Dashboard
├─ Create function (orange button)
└─ Functions (empty list)
```

### Action 2.2: Create Function

**Click "Create function"**

Fill in the form:
```
Function name:          simple-processor
Runtime:                Python 3.11
Execution role:         Create new role
                        (with basic Lambda permissions)
```

Click **"Create function"**

**Result:**
```
✓ Function created!
Function Name: simple-processor
```

### Action 2.3: You Should See

A code editor with default code:
```python
def lambda_handler(event, context):
    return 'Hello from Lambda!'
```

---

## STEP 3: Write Lambda Code (2 minutes)

### Action 3.1: Replace Code

1. Select **all** the default code (Ctrl+A)
2. Delete it
3. Paste this code:

```python
def lambda_handler(event, context):
    """
    Lambda function that processes SQS messages
    """
    
    print("=" * 50)
    print("Lambda triggered!")
    print("=" * 50)
    
    # Process each message
    for message in event['Records']:
        message_id = message['messageId']
        body = message['body']
        
        print(f"\nMessage ID: {message_id}")
        print(f"Content: {body}")
        print("✓ Processed!")
    
    return {'statusCode': 200, 'body': 'Success'}
```

### Action 3.2: Deploy Code

Click the orange **"Deploy"** button

**Wait for confirmation:**
```
✓ Deployment successful
```

---

## STEP 4: Grant Lambda Permissions (5 minutes)

Lambda needs permission to read from SQS queue.

### Action 4.1: Find Execution Role

1. On Lambda page, click **"Configuration"** tab
2. Look for **"Execution role"** on the left
3. Click the role name (blue link)
   - Opens IAM Console in new tab

### Action 4.2: Add Permission

On IAM role page:

1. Click **"Add permissions"** (dropdown)
2. Select **"Create inline policy"**

### Action 4.3: Create Policy

1. Click **"JSON"** tab
2. Delete everything
3. Paste this:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes"
            ],
            "Resource": "arn:aws:sqs:us-east-1:123456789:my-simple-queue"
        }
    ]
}
```

**⚠️ IMPORTANT:** Replace `123456789` with your AWS Account ID

Find your Account ID:
- Top right corner of AWS Console
- Click your account name
- See "Account ID"

### Action 4.4: Create Policy

1. Click **"Review policy"**
2. Click **"Create policy"**

**Result:**
```
✓ Permission granted!
```

---

## STEP 5: Connect Lambda to SQS (3 minutes)

### Action 5.1: Add Trigger

Go back to **Lambda Console** (click Lambda tab)

On function page:
1. Look for **"Add trigger"** button
2. Click it

### Action 5.2: Configure Trigger

Fill in the form:

```
Trigger source:    SQS (select from dropdown)
SQS queue:         my-simple-queue (select your queue)
Batch size:        10 (default)
Enabled:           ✓ Check this box
```

### Action 5.3: Finish

Click the blue **"Add"** button

**Result:**
```
✓ Trigger added!
Lambda now watches your SQS queue
```

---

## STEP 6: Test It! (5 minutes)

### Action 6.1: Send Message

Go to **SQS Console**

1. Click your queue: **my-simple-queue**
2. Click **"Send message"** (orange button)
3. Type in message: `Hello Lambda! This is a test!`
4. Click **"Send message"**

**Result:**
```
✓ Message sent!
Message ID: abc123def456
```

### Action 6.2: See Lambda Trigger

Go back to **Lambda Console**

1. On your function page
2. Click **"Monitor"** tab
3. Look for **"Invocations"**

**You should see:**
```
Invocations: 1  ← Lambda was triggered!
```

### Action 6.3: Check Output

1. Click **"View logs in CloudWatch"**

**You should see:**
```
Lambda triggered!
Message ID: abc123def456
Content: Hello Lambda! This is a test!
✓ Processed!
```

### ✅ SUCCESS!

Lambda automatically triggered when message arrived! 🎉

---

# PART 4: LAMBDA CODE EXAMPLES

## Example 1: Simplest (Copy This First)

```python
def lambda_handler(event, context):
    """Simplest possible Lambda function"""
    
    for message in event['Records']:
        print(f"Message: {message['body']}")
    
    return 'Done!'
```

**How to test:**
1. Paste into Lambda
2. Deploy
3. Send message to SQS
4. See output in CloudWatch logs

---

## Example 2: Print Message Details

```python
def lambda_handler(event, context):
    """Print detailed message info"""
    
    total = len(event['Records'])
    print(f"Processing {total} message(s)...")
    
    for i, message in enumerate(event['Records'], 1):
        msg_id = message['messageId']
        body = message['body']
        timestamp = message['attributes']['SentTimestamp']
        
        print(f"\n{i}. Message ID: {msg_id}")
        print(f"   Content: {body}")
        print(f"   Sent at: {timestamp}")
    
    return f'Processed {total} messages'
```

---

## Example 3: Process JSON Messages

```python
import json

def lambda_handler(event, context):
    """Process JSON-formatted messages"""
    
    for message in event['Records']:
        # Parse JSON string to dictionary
        data = json.loads(message['body'])
        
        name = data.get('name', 'Unknown')
        email = data.get('email', 'unknown@example.com')
        
        print(f"Name: {name}")
        print(f"Email: {email}")
    
    return 'Done!'
```

**How to send JSON message:**

```python
import boto3
import json

sqs = boto3.client('sqs')

message_dict = {
    'name': 'Alice Johnson',
    'email': 'alice@example.com'
}

sqs.send_message(
    QueueUrl='YOUR_QUEUE_URL',
    MessageBody=json.dumps(message_dict)  # Convert to JSON string
)
```

---

## Example 4: Process Orders

```python
import json

def lambda_handler(event, context):
    """Process e-commerce orders"""
    
    for message in event['Records']:
        order = json.loads(message['body'])
        
        order_id = order['order_id']
        customer = order['customer']
        amount = order['amount']
        items = order.get('items', [])
        
        print(f"Order #{order_id}")
        print(f"Customer: {customer}")
        print(f"Total: ${amount}")
        print(f"Items: {', '.join(items)}")
        print("✓ Order processed!")
    
    return 'Done!'
```

**Send message:**

```python
import boto3
import json

sqs = boto3.client('sqs')

order = {
    'order_id': 12345,
    'customer': 'John Doe',
    'amount': 99.99,
    'items': ['Laptop', 'Mouse', 'Keyboard']
}

sqs.send_message(
    QueueUrl='YOUR_QUEUE_URL',
    MessageBody=json.dumps(order)
)
```

---

## Example 5: Error Handling (Best Practice)

```python
import json

def lambda_handler(event, context):
    """Process messages with error handling"""
    
    batch_item_failures = []
    
    for record in event['Records']:
        message_id = record['messageId']
        
        try:
            # Parse message
            data = json.loads(record['body'])
            
            # Validate
            if 'id' not in data:
                raise ValueError("Missing 'id' field")
            
            # Process
            print(f"Processing: {data}")
        
        except json.JSONDecodeError as e:
            print(f"Invalid JSON: {e}")
            batch_item_failures.append({"itemId": message_id})
        except ValueError as e:
            print(f"Validation error: {e}")
            batch_item_failures.append({"itemId": message_id})
        except Exception as e:
            print(f"Error: {e}")
            batch_item_failures.append({"itemId": message_id})
    
    # Return failed messages for retry
    return {"batchItemFailures": batch_item_failures}
```

---

## Example 6: With Message Attributes

```python
import json

def lambda_handler(event, context):
    """Process messages with custom attributes"""
    
    for message in event['Records']:
        body = json.loads(message['body'])
        attributes = message.get('messageAttributes', {})
        
        # Extract attribute
        priority = attributes.get('priority', {}).get('stringValue', 'normal')
        
        print(f"Body: {body}")
        print(f"Priority: {priority}")
        
        # Route based on priority
        if priority == 'high':
            print("Fast processing!")
        else:
            print("Normal processing")
    
    return 'Done!'
```

**Send with attributes:**

```python
import json
import boto3

sqs = boto3.client('sqs')

sqs.send_message(
    QueueUrl='YOUR_QUEUE_URL',
    MessageBody=json.dumps({'data': 'example'}),
    MessageAttributes={
        'priority': {
            'StringValue': 'high',
            'DataType': 'String'
        }
    }
)
```

---

## Example 7: Save to DynamoDB

```python
import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ProcessedMessages')

def lambda_handler(event, context):
    """Process message and save to DynamoDB"""
    
    for message in event['Records']:
        message_id = message['messageId']
        body = json.loads(message['body'])
        
        try:
            # Process
            print(f"Processing: {body}")
            
            # Save to DynamoDB
            table.put_item(
                Item={
                    'messageId': message_id,
                    'timestamp': datetime.now().isoformat(),
                    'data': body,
                    'status': 'processed'
                }
            )
            
            print(f"Saved to DynamoDB")
        
        except Exception as e:
            print(f"Error: {e}")
            raise
    
    return 'Done!'
```

---

## Example 8: Idempotent Processing

```python
import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ProcessedMessages')

def lambda_handler(event, context):
    """Idempotent processing (safe for retries)"""
    
    for message in event['Records']:
        message_id = message['messageId']
        body = json.loads(message['body'])
        
        try:
            # Check if already processed
            response = table.get_item(Key={'messageId': message_id})
            
            if 'Item' in response:
                print(f"Already processed: {message_id}")
                continue
            
            # Process message
            print(f"Processing: {body}")
            
            # Mark as processed FIRST
            table.put_item(
                Item={
                    'messageId': message_id,
                    'timestamp': datetime.now().isoformat(),
                    'status': 'processed'
                }
            )
            
            # Then do external actions
            perform_action(body)
        
        except Exception as e:
            print(f"Error: {e}")
            raise
    
    return 'Done!'

def perform_action(data):
    """External action that should only happen once"""
    print(f"Performing action: {data}")
    # Charge card, send email, etc.
```

---

## Example 9: With Timeout Protection

```python
def lambda_handler(event, context):
    """Process with Lambda timeout awareness"""
    
    batch_item_failures = []
    remaining_time = context.get_remaining_time_in_millis()
    
    for record in event['Records']:
        message_id = record['messageId']
        
        # Check if enough time to process
        if remaining_time < 5000:  # Less than 5 seconds left
            print("Not enough time, retry later")
            batch_item_failures.append({"itemId": message_id})
            continue
        
        try:
            print(f"Processing: {message_id}")
            # Do work...
        except Exception as e:
            print(f"Error: {e}")
            batch_item_failures.append({"itemId": message_id})
        
        remaining_time = context.get_remaining_time_in_millis()
    
    return {"batchItemFailures": batch_item_failures}
```

---

## Example 10: Conditional Routing

```python
import json

def lambda_handler(event, context):
    """Route messages to different handlers"""
    
    batch_item_failures = []
    
    for record in event['Records']:
        message_id = record['messageId']
        
        try:
            data = json.loads(record['body'])
            message_type = data.get('type')
            
            # Route based on type
            if message_type == 'order':
                handle_order(data)
            elif message_type == 'payment':
                handle_payment(data)
            elif message_type == 'notification':
                handle_notification(data)
            else:
                raise ValueError(f"Unknown type: {message_type}")
        
        except Exception as e:
            print(f"Error: {e}")
            batch_item_failures.append({"itemId": message_id})
    
    return {"batchItemFailures": batch_item_failures}

def handle_order(data):
    print(f"Handling order: {data}")

def handle_payment(data):
    print(f"Handling payment: {data}")

def handle_notification(data):
    print(f"Handling notification: {data}")
```

---

# PART 5: ADVANCED TOPICS

## Batch Processing

### Understanding Batch Size

**Batch Size = How many messages at once**

```
Batch Size 1:   Lambda invoked 10 times (1 msg each)
Batch Size 10:  Lambda invoked 1 time (10 msgs)
```

**When to use:**

- **Size 1-3:** Time-critical, low latency needed
- **Size 5-10:** Most applications (good balance)
- **Size 10:** Batch processing, cost optimization

**Configure in Lambda Console:**
1. Go to Lambda function
2. Click trigger (SQS)
3. Click "Edit"
4. Change "Batch size"
5. Save

---

## Dead Letter Queue (DLQ)

### What is DLQ?

Special queue for messages that failed processing.

**Flow:**
```
Main Queue → Lambda tries to process
           ├─ Success → Delete message
           └─ Failure (3x) → Send to DLQ
```

### Setup DLQ

#### Step 1: Create DLQ Queue

In SQS Console:
1. Create queue: `my-queue-dlq`
2. Keep settings default

#### Step 2: Link to Main Queue

On main queue:
1. Click "Edit"
2. Scroll to "Dead-letter queue"
3. Enable it
4. Select `my-queue-dlq`
5. Set "Maximum receives" to 3
6. Save

#### Step 3: Process DLQ

To handle failed messages:

```python
import boto3
import json

sqs = boto3.client('sqs')
DLQ_URL = 'your-dlq-url'
MAIN_QUEUE_URL = 'your-main-queue-url'

# Get failed messages
response = sqs.receive_message(
    QueueUrl=DLQ_URL,
    MaxNumberOfMessages=10
)

for msg in response.get('Messages', []):
    print(f"Failed message: {msg['Body']}")
    
    # Investigate and fix
    # Then optionally replay to main queue
    sqs.send_message(
        QueueUrl=MAIN_QUEUE_URL,
        MessageBody=msg['Body']
    )
    
    # Delete from DLQ
    sqs.delete_message(
        QueueUrl=DLQ_URL,
        ReceiptHandle=msg['ReceiptHandle']
    )
```

---

## Message Attributes

### What Are Message Attributes?

Custom metadata you attach to messages.

**Benefits:**
- Don't count toward message size
- Visible without parsing message
- Useful for routing

### Send with Attributes

```python
import boto3
import json

sqs = boto3.client('sqs')

message = {'data': 'example'}

sqs.send_message(
    QueueUrl='YOUR_QUEUE_URL',
    MessageBody=json.dumps(message),
    MessageAttributes={
        'priority': {
            'StringValue': 'high',
            'DataType': 'String'
        },
        'order_type': {
            'StringValue': 'urgent',
            'DataType': 'String'
        },
        'retry_count': {
            'StringValue': '0',
            'DataType': 'Number'
        }
    }
)
```

### Read Attributes in Lambda

```python
def lambda_handler(event, context):
    
    for message in event['Records']:
        body = message['body']
        attributes = message.get('messageAttributes', {})
        
        priority = attributes.get('priority', {}).get('stringValue', 'normal')
        order_type = attributes.get('order_type', {}).get('stringValue', 'normal')
        
        print(f"Body: {body}")
        print(f"Priority: {priority}")
        print(f"Order Type: {order_type}")
    
    return 'Done!'
```

---

## FIFO Queues

### Standard vs FIFO

| Aspect | Standard | FIFO |
|--------|----------|------|
| **Order** | Best effort | Guaranteed |
| **Speed** | Very fast | Slightly slower |
| **Duplicates** | Possible | Prevented |
| **Name** | `my-queue` | `my-queue.fifo` |
| **Throughput** | Unlimited | 300 msg/sec |
| **Cost** | $0.40/million | $0.50/million |
| **Use Case** | General purpose | Order matters |

### Create FIFO Queue

In SQS Console:
1. Create queue
2. Name: `my-queue.fifo` (must end with .fifo)
3. Type: FIFO
4. Create

### Send to FIFO Queue

```python
import boto3
import json

sqs = boto3.client('sqs')

# All messages in same group must be sent with same Group ID
sqs.send_message(
    QueueUrl='YOUR_QUEUE.fifo_URL',
    MessageBody=json.dumps({'step': 1}),
    MessageGroupId='order-123',  # Required for FIFO
    MessageDeduplicationId='step-1'  # Optional, prevents duplicates
)
```

### Process FIFO in Lambda

```python
import json

def lambda_handler(event, context):
    """FIFO messages are processed in order"""
    
    for message in event['Records']:
        data = json.loads(message['body'])
        
        # Messages are guaranteed in order
        print(f"Step: {data['step']}")
    
    return 'Done!'
```

---

## Visibility Timeout

### What is It?

Time a message stays hidden after being read.

**Default:** 30 seconds
**Range:** 0-43200 seconds (12 hours)

### Why Important?

```
1. Lambda reads message
2. Message becomes invisible (hidden) for 30 seconds
3. If Lambda crashes, message becomes visible again
4. Another Lambda instance can retry
```

### Configure

**In SQS Console:**
1. Select queue
2. Click "Edit"
3. Visibility timeout: Set to match Lambda processing time
4. Save

**Example:**
- Lambda takes 5 minutes to process → Set visibility to 360 seconds
- Lambda takes 30 seconds → Set visibility to 60 seconds

---

## Error Handling Strategies

### Strategy 1: All or Nothing

Simplest approach - if one fails, all fail:

```python
def lambda_handler(event, context):
    for message in event['Records']:
        process(message)  # If this fails, whole batch fails
    return 'Done!'
```

### Strategy 2: Batch Item Failures (Recommended)

Report individual failures:

```python
def lambda_handler(event, context):
    batch_item_failures = []
    
    for record in event['Records']:
        try:
            process(record)
        except Exception as e:
            batch_item_failures.append({"itemId": record['messageId']})
    
    return {"batchItemFailures": batch_item_failures}
```

**Benefits:**
- Successful messages don't retry
- Only failed messages retry
- More efficient

### Strategy 3: Custom Error Handling

Differentiate error types:

```python
def lambda_handler(event, context):
    batch_item_failures = []
    
    for record in event['Records']:
        try:
            data = json.loads(record['body'])
            validate(data)
            process(data)
        
        except json.JSONDecodeError:
            # Invalid data - don't retry
            print("Invalid JSON, skipping")
            continue
        
        except ValidationError:
            # Validation failed - don't retry
            print("Validation failed, skipping")
            continue
        
        except Exception as e:
            # Unknown error - retry
            print(f"Error: {e}")
            batch_item_failures.append({"itemId": record['messageId']})
    
    return {"batchItemFailures": batch_item_failures}
```

---

# PART 6: MONITORING & TROUBLESHOOTING

## CloudWatch Monitoring

### View Lambda Metrics

**In Lambda Console:**
1. Go to function
2. Click "Monitor" tab
3. See metrics:
   - Invocations
   - Duration
   - Errors
   - Throttles

### CloudWatch Logs

**View logs:**
1. Lambda Monitor tab
2. Click "View logs in CloudWatch"
3. See all output

**Command line:**
```bash
# View live logs
aws logs tail /aws/lambda/simple-processor --follow

# View recent logs
aws logs tail /aws/lambda/simple-processor

# Search for errors
aws logs tail /aws/lambda/simple-processor --grep ERROR
```

### SQS Metrics

**In SQS Console:**
1. Select queue
2. Scroll down to "CloudWatch metrics"
3. See:
   - Messages visible
   - Messages in flight
   - Messages sent/received

---

## Troubleshooting Guide

### Problem 1: Lambda Doesn't Trigger

**Check:**
1. Is trigger configured?
   - Lambda → Triggers tab → See SQS listed?
2. Is queue receiving messages?
   - SQS Console → Queue → See message count > 0?
3. Is Lambda enabled?
   - Lambda → Configuration → Execution role set?

**Solution:**
1. Go to Lambda function
2. Click "Add trigger"
3. Select SQS
4. Select your queue
5. Click "Add"

---

### Problem 2: Permission Denied Error

**Error Message:**
```
User: arn:aws:iam::123456789:role/lambda-role is not authorized to perform: sqs:ReceiveMessage
```

**Solution:**
1. Lambda function → Configuration tab
2. Execution role → Click role name
3. Add policy (see Part 3, Action 4.3)
4. Refresh Lambda, try again

---

### Problem 3: Message Not Being Processed

**Check:**
1. View logs: Lambda Monitor → View logs in CloudWatch
2. Look for errors
3. Check message format (is it valid JSON?)

**Test:**
1. Send simple text message (not JSON)
2. Watch logs
3. See if Lambda processes it

---

### Problem 4: Lambda Timeout

**Error:**
```
Task timed out after 300.00 seconds
```

**Solution:**
1. Lambda → Configuration tab
2. Timeout → Increase it (max 15 minutes)
3. Or optimize your code to run faster

---

### Problem 5: High Memory Usage

**Solution:**
1. Lambda → Configuration tab
2. Memory → Increase it (higher = faster CPU)
3. Test with 1024 MB or 1536 MB

---

## Debugging Tips

### Print Everything

```python
def lambda_handler(event, context):
    print("Event:")
    print(json.dumps(event, indent=2))
    
    for message in event['Records']:
        print(f"\nMessage ID: {message['messageId']}")
        print(f"Body: {message['body']}")
        print(f"Attributes: {message.get('messageAttributes', {})}")
    
    return 'Done!'
```

### Log Errors with Full Stack Trace

```python
import traceback

def lambda_handler(event, context):
    try:
        for message in event['Records']:
            process(message)
    except Exception as e:
        print(f"Error: {e}")
        traceback.print_exc()  # Print full stack trace
        raise

def process(message):
    # Your code here
    pass
```

### Use Timestamps

```python
from datetime import datetime

def lambda_handler(event, context):
    start = datetime.now()
    
    for message in event['Records']:
        print(f"[{datetime.now()}] Processing: {message['messageId']}")
        process(message)
    
    duration = datetime.now() - start
    print(f"[{datetime.now()}] Completed in {duration.total_seconds()}s")
    
    return 'Done!'
```

---

# PART 7: PRODUCTION DEPLOYMENT

## Using Python Boto3 in Production

### Install Dependencies

```bash
pip install boto3
```

### Create Production Script

**File: `send_messages.py`**

```python
import boto3
import json
import os
from datetime import datetime

# Get queue URL from environment variable
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')

if not QUEUE_URL:
    raise ValueError("SQS_QUEUE_URL environment variable not set")

sqs = boto3.client('sqs', region_name='us-east-1')

def send_order_message(order_data):
    """Send order message to SQS"""
    
    message = {
        'order_id': order_data['order_id'],
        'customer': order_data['customer'],
        'amount': order_data['amount'],
        'timestamp': datetime.now().isoformat()
    }
    
    response = sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(message),
        MessageAttributes={
            'source': {
                'StringValue': 'web-app',
                'DataType': 'String'
            },
            'priority': {
                'StringValue': 'normal',
                'DataType': 'String'
            }
        }
    )
    
    return response['MessageId']

def send_batch(orders):
    """Send multiple messages in batch"""
    
    entries = []
    for i, order in enumerate(orders):
        entries.append({
            'Id': str(i),
            'MessageBody': json.dumps(order)
        })
    
    response = sqs.send_message_batch(
        QueueUrl=QUEUE_URL,
        Entries=entries
    )
    
    return len(response['Successful'])

if __name__ == '__main__':
    # Single message
    order = {
        'order_id': 12345,
        'customer': 'John Doe',
        'amount': 99.99
    }
    
    msg_id = send_order_message(order)
    print(f"✓ Message sent: {msg_id}")
    
    # Batch messages
    orders = [
        {'order_id': 101, 'customer': 'Alice', 'amount': 50.00},
        {'order_id': 102, 'customer': 'Bob', 'amount': 75.00},
        {'order_id': 103, 'customer': 'Charlie', 'amount': 100.00}
    ]
    
    count = send_batch(orders)
    print(f"✓ Batch sent: {count} messages")
```

### Run Script

```bash
export SQS_QUEUE_URL='https://sqs.us-east-1.amazonaws.com/123456789/my-queue'
python send_messages.py
```

---

## Using SAM for Deployment

### What is SAM?

**SAM = AWS Serverless Application Model**

Infrastructure as Code for serverless applications.

### SAM Template

**File: `template.yaml`**

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: SQS + Lambda Application

Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]

Resources:
  # SQS Queue
  MessageQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub 'my-queue-${Environment}'
      VisibilityTimeout: 300

  # Dead Letter Queue
  MessageQueueDLQ:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub 'my-queue-dlq-${Environment}'

  # Lambda Function
  ProcessorFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub 'processor-${Environment}'
      CodeUri: src/
      Handler: app.lambda_handler
      Runtime: python3.11
      Timeout: 60
      MemorySize: 512
      Policies:
        - SQSPollerPolicy:
            QueueName: !GetAtt MessageQueue.QueueName
      Events:
        SQSEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt MessageQueue.Arn
            BatchSize: 10

Outputs:
  QueueUrl:
    Description: SQS Queue URL
    Value: !Ref MessageQueue
  
  FunctionArn:
    Description: Lambda Function ARN
    Value: !GetAtt ProcessorFunction.Arn
```

### Deploy with SAM

```bash
# Build
sam build

# Deploy
sam deploy --guided

# Answer questions:
# Stack name: my-sqs-lambda-stack
# Region: us-east-1
# Confirm changes: Y
# Allow SAM to create IAM roles: Y
```

---

## Production Checklist

- [ ] Queue created (Standard or FIFO)
- [ ] DLQ created and linked
- [ ] Lambda function created
- [ ] Lambda execution role has SQS permissions
- [ ] Event source mapping configured
- [ ] Batch size optimized for workload
- [ ] Visibility timeout ≥ Lambda max duration
- [ ] Lambda timeout set appropriately
- [ ] Memory optimized
- [ ] Error handling implemented (batch item failures)
- [ ] Logging enabled and monitored
- [ ] CloudWatch alarms created
- [ ] Testing completed
- [ ] Monitoring dashboard created
- [ ] Documentation written
- [ ] Runbook for troubleshooting created

---

# PART 8: BEST PRACTICES

## Code Quality

### Do's ✅

```python
# ✅ Good: Proper error handling
def lambda_handler(event, context):
    batch_item_failures = []
    
    for record in event['Records']:
        try:
            process(record)
        except Exception as e:
            logger.error(f"Error: {e}")
            batch_item_failures.append({"itemId": record['messageId']})
    
    return {"batchItemFailures": batch_item_failures}

# ✅ Good: Idempotent processing
def lambda_handler(event, context):
    for message in event['Records']:
        if already_processed(message['messageId']):
            continue
        
        process(message)
        mark_processed(message['messageId'])

# ✅ Good: Proper logging
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

logger.info(f"Processing message {message_id}")
logger.error(f"Error: {error}")
```

### Don'ts ❌

```python
# ❌ Bad: No error handling
def lambda_handler(event, context):
    for message in event['Records']:
        process(message)  # If fails, whole batch fails

# ❌ Bad: Side effects without tracking
def lambda_handler(event, context):
    for message in event['Records']:
        charge_card(message)  # If fails on retry = double charge!

# ❌ Bad: No logging
def lambda_handler(event, context):
    for message in event['Records']:
        process(message)
    return 'Done!'
```

---

## Performance Optimization

### Batch Size Tuning

```
Small (1-5):  
  - Pro: Lower latency
  - Con: More invocations = more cost

Medium (5-10):
  - Good balance for most apps

Large (10+):
  - Pro: Fewer invocations = lower cost
  - Con: Longer latency, bigger failures
```

### Memory Optimization

```
Higher memory = Faster CPU = Faster execution

Trade-off to find:
- 512 MB: Slow but cheap
- 1024 MB: Good balance
- 1536+ MB: Fast but more expensive
```

### Connection Pooling

```python
import boto3

# ✅ Good: Reuse client across invocations
s3 = boto3.client('s3')

def lambda_handler(event, context):
    for message in event['Records']:
        # Reuse connection
        s3.put_object(...)

# ❌ Bad: Create new client every invocation
def lambda_handler(event, context):
    for message in event['Records']:
        s3 = boto3.client('s3')  # Slow!
        s3.put_object(...)
```

---

## Security Best Practices

### Use IAM Roles

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage"
            ],
            "Resource": "arn:aws:sqs:region:account:queue-name"
        }
    ]
}
```

Don't use wildcard permissions!

### Encrypt Messages

For sensitive data, enable encryption:

```bash
aws sqs set-queue-attributes \
  --queue-url YOUR_QUEUE_URL \
  --attributes KmsMasterKeyId=alias/aws/sqs
```

### Use Environment Variables

```python
import os

QUEUE_URL = os.environ['QUEUE_URL']
API_KEY = os.environ['API_KEY']  # From secrets manager
```

---

## Cost Optimization

### 1. Use Long Polling

Lambda already uses long polling (wait_time_seconds=20)

**Saves up to 90% on API calls!**

### 2. Batch Processing

Process multiple messages per invocation:

```
10 messages in 1 invocation = cheaper than 10 invocations
```

### 3. Right-Size Memory

```
Test different memory levels
Find sweet spot between cost and speed
```

### 4. Delete Messages Immediately

Messages deleted = not retried = lower costs

### 5. Monitor and Alert

Use CloudWatch to track:
- Lambda invocations
- Queue depth
- Error rates
- Duration

---

## Monitoring Best Practices

### Create CloudWatch Alarms

```bash
# Alert on queue depth
aws cloudwatch put-metric-alarm \
  --alarm-name queue-depth-high \
  --metric-name ApproximateNumberOfMessagesVisible \
  --namespace AWS/SQS \
  --statistic Average \
  --period 300 \
  --threshold 1000 \
  --comparison-operator GreaterThanThreshold

# Alert on Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name lambda-errors \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold
```

### Dashboard

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

# Create custom metrics
cloudwatch.put_metric_data(
    Namespace='MyApp',
    MetricData=[
        {
            'MetricName': 'ProcessedOrders',
            'Value': 100,
            'Unit': 'Count'
        }
    ]
)
```

---

## Disaster Recovery

### What Can Go Wrong?

1. **Lambda crashes** → Messages retry (DLQ catches)
2. **Queue fills up** → Lambda scales up automatically
3. **Messages corrupted** → Goes to DLQ for investigation
4. **Lambda bugs** → Deploy new version immediately

### Prevention

1. **DLQ enabled** → Catch failures
2. **Error handling** → Handle edge cases
3. **Testing** → Test failure scenarios
4. **Monitoring** → Know when things break
5. **Alarms** → Alert on issues

### Recovery

```python
import boto3
import json

sqs = boto3.client('sqs')

def replay_dlq_to_main():
    """Move messages from DLQ back to main queue"""
    
    dlq_url = 'YOUR_DLQ_URL'
    main_url = 'YOUR_MAIN_QUEUE_URL'
    
    # Get DLQ messages
    response = sqs.receive_message(
        QueueUrl=dlq_url,
        MaxNumberOfMessages=10
    )
    
    # Send back to main queue
    for msg in response.get('Messages', []):
        sqs.send_message(
            QueueUrl=main_url,
            MessageBody=msg['Body']
        )
        
        # Delete from DLQ
        sqs.delete_message(
            QueueUrl=dlq_url,
            ReceiptHandle=msg['ReceiptHandle']
        )

if __name__ == '__main__':
    replay_dlq_to_main()
    print("✓ DLQ messages replayed to main queue")
```

---

## Testing

### Unit Testing

```python
import json
import unittest
from app import lambda_handler, process_order

class TestOrderProcessing(unittest.TestCase):
    
    def test_valid_order(self):
        """Test processing valid order"""
        order = {
            'order_id': 123,
            'customer': 'Test',
            'amount': 99.99
        }
        result = process_order(order)
        self.assertTrue(result)
    
    def test_invalid_order(self):
        """Test processing invalid order"""
        order = {'invalid': 'data'}
        with self.assertRaises(ValueError):
            process_order(order)

if __name__ == '__main__':
    unittest.main()
```

### Integration Testing

```python
import boto3
import json
import time

def test_end_to_end():
    """Test full flow: Send message → Lambda processes"""
    
    sqs = boto3.client('sqs')
    queue_url = 'YOUR_QUEUE_URL'
    
    # Send message
    message = {'test': 'data'}
    sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message)
    )
    
    # Wait for Lambda to process (up to 10 seconds)
    for _ in range(10):
        response = sqs.get_queue_attributes(
            QueueUrl=queue_url,
            AttributeNames=['ApproximateNumberOfMessages']
        )
        
        if int(response['Attributes']['ApproximateNumberOfMessages']) == 0:
            print("✓ Message processed!")
            return True
        
        time.sleep(1)
    
    print("✗ Message not processed")
    return False

if __name__ == '__main__':
    test_end_to_end()
```

---

## Documentation

### Write a README

```markdown
# My SQS Lambda Application

## Overview
Processes orders from SQS queue and saves to database.

## Architecture
- SQS Queue: my-queue (receives orders)
- DLQ: my-queue-dlq (failed orders)
- Lambda: processor (processes orders)
- Database: DynamoDB (stores results)

## Setup
1. Create SQS queue
2. Create Lambda function
3. Deploy code
4. Add trigger

## Monitoring
- CloudWatch Logs: /aws/lambda/processor
- CloudWatch Metrics: Check queue depth
- Alarms: Alert if queue depth > 1000

## Troubleshooting
- Queue empty? Check if Lambda is processing
- Lambda failing? Check CloudWatch logs
- High costs? Reduce batch size or memory
```

### API Documentation

```python
def lambda_handler(event, context):
    """
    Process orders from SQS
    
    Args:
        event: {
            'Records': [
                {
                    'body': JSON string with order data,
                    'messageId': unique message ID,
                    'messageAttributes': custom attributes
                }
            ]
        }
        context: Lambda context object
    
    Returns:
        {
            'batchItemFailures': [
                {'itemId': 'message_id'}  # Only failed messages
            ]
        }
    
    Raises:
        Exception: On processing error (will retry)
    """
```

---

## Common Patterns

### Pattern 1: Fan-Out

```
SQS Queue → Lambda → Multiple Destinations
                  ├─ DynamoDB
                  ├─ S3
                  ├─ SNS
                  └─ HTTP API
```

### Pattern 2: Pipeline

```
SQS1 → Lambda1 → Process → SQS2 → Lambda2 → Save
```

### Pattern 3: Circuit Breaker

```python
import time

failed_count = 0
MAX_FAILURES = 5

def is_circuit_open():
    global failed_count
    if failed_count > MAX_FAILURES:
        return True
    return False

def lambda_handler(event, context):
    global failed_count
    
    if is_circuit_open():
        print("Circuit open, deferring processing")
        return {"batchItemFailures": [{"itemId": r['messageId']} for r in event['Records']]}
    
    for record in event['Records']:
        try:
            process(record)
            failed_count = 0  # Reset on success
        except Exception as e:
            failed_count += 1
            if failed_count > MAX_FAILURES:
                print("Too many failures, opening circuit")
```

---

## Conclusion

You now know:

✅ **Concepts:** SQS, Lambda, Event triggers
✅ **Setup:** Create queues, functions, connections
✅ **Code:** Simple to advanced Lambda examples
✅ **Advanced:** FIFO, DLQ, error handling
✅ **Production:** Deployment, monitoring, troubleshooting
✅ **Best Practices:** Security, performance, cost optimization

---

## Quick Reference

### Send Message

```python
import boto3
sqs = boto3.client('sqs')
sqs.send_message(
    QueueUrl='YOUR_URL',
    MessageBody='Your message'
)
```

### Basic Lambda

```python
def lambda_handler(event, context):
    for message in event['Records']:
        print(f"Got: {message['body']}")
    return 'Done!'
```

### Deploy

1. Create SQS queue
2. Create Lambda function
3. Write code
4. Add SQS trigger
5. Send message → Lambda triggers automatically!

---

**Congratulations! You're now a SQS + Lambda expert! 🎉**

Start with Part 1, follow Part 3 for AWS Console setup, use Part 4 for code examples, and refer to other parts as needed.

Good luck! 🚀

---

**Last Updated:** 2024
**Version:** 1.0
**Scope:** Beginner to Advanced
