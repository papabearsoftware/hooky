[
    {
        %{ if commands }"command": ${commands}%{ endif },
        "cpu": ${cpu},
        "essential": true,
        "environment": [
            {
                "name": "POSTGRES_HOST",
                "value": "${db_hostname}"
            },
            {
                "name": "POSTGRES_USER",
                "value": "${db_user}",
            },
            {
                "name": "POSTGRES_PASSWORD",
                "value": "${db_password}"
            },
            {
                "name": "POSTGRES_DB",
                "value": "${db_name}"  
            },
            {
                "name": "JOB_THREAD_POOL_SIZE",
                "value": ${job_thread_pool_size}
            },
            {
                "name": "MAX_WEBHOOK_ERROR_COUNT",
                "value": ${max_webhook_retry_error_count}
            },
            {
                "name": "RUN_ASYNC_JOBS",
                "value": "${run_async_jobs}"
            },
            {
                "name": "REQUEST_TIMEOUT",
                "value": ${request_timeout}
            }
        ],  
        "healthCheck": {
            "command": [ "CMD-SHELL", "curl -s 'http://localhost:5000/api/v1/healthcheck' || exit 1" ],
            "interval": 30,
            "startPeriod": 30,
            "timeout": 15,
            "retries": 2
        },
        "mountPoints": [],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "hooky",
                "awslogs-region": "${region}",
                "awslogs-stream-prefix": "api"
            }
        },
        "volumesFrom": [],
        "image": "${container_image}",
        "memory": ${memory},
        "memoryReservation": ${memory_soft_limit},
        "name": "hooky-api",
        "portMappings": [
            {
                "containerPort": 5000,
                "hostPort": 5000,
                "protocol": "tcp"
            }
        ],
        "dependsOn": [],
        "privileged": false,
        "startTimeout": 60,
        "stopTimeout": 30
    }
]