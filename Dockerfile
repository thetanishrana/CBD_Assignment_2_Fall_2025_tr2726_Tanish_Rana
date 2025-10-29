# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory in container
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# Expose Flask port
EXPOSE 5000

# Set environment variables
ENV FLASK_ENV=production
ENV MONGO_HOST=mongodb
ENV MONGO_PORT=27017

# Run the application
CMD ["python", "app.py"]
