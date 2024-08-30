# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

# Create a subnet in the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "my_subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

# Create a route table and route to the internet gateway
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my_route_table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a security group
resource "aws_security_group" "allow_http_app" {
  name        = "allow_http_app"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the new subnet
resource "aws_instance" "flask_app" {
  ami           = var.ami # Update with the latest Ubuntu AMI ID
  instance_type = "t2.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.my_subnet.id

  user_data = <<-EOF
                #!/bin/bash

                # Update and install packages
                sudo apt-get update -y
                sudo apt-get install -y python3 python3-venv git curl unzip wget gnupg libnss3 libgconf-2 libxss1 libasound2 libxtst6 libgtk-3-0

                # Add Google Chrome repository and install Google Chrome
                sudo apt-get install -y wget gnupg
                wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
                sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
                sudo apt-get update -y
                sudo apt-get install -y google-chrome-stable

                # Download and set up ChromeDriver
                CHROMEDRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE)
                wget -N https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip
                unzip chromedriver_linux64.zip
                rm chromedriver_linux64.zip
                sudo mv chromedriver /usr/local/bin/chromedriver
                sudo chown root:root /usr/local/bin/chromedriver
                sudo chmod 0755 /usr/local/bin/chromedriver

                # Clone the repository and set up the virtual environment
                git clone https://github.com/MDavidHernandezP/JobWebScraperApp.git /home/ubuntu/flaskapp
                cd /home/ubuntu/flaskapp

                # Install Python dependencies within the virtual environment
                pip install --no-cache-dir -r requirements.txt

                # Set environment variables and start Flask application
                export FLASK_APP=app.py
                export FLASK_RUN_HOST=0.0.0.0
                export FLASK_RUN_PORT=5000
                nohup flask run --host=0.0.0.0 --port=5000 &

              EOF

  tags = {
    Name = "FlaskAppInstance"
  }

  security_groups = [aws_security_group.allow_http_app.id]
}
