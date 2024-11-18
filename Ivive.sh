livenessProbe:
  exec:
    command:
    - python
    - /path/to/your-script.py
  initialDelaySeconds: 10
  periodSeconds: 5