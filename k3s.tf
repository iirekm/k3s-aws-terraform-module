data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "keypair" {
  public_key = file("~/.ssh/id_rsa.pub")
}

data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}

resource "aws_security_group" "security_group" {
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${trimspace(data.http.my_ip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "instance_type" {
  default = "t3.micro"
}

variable "kubeconfig_filename_suffix" {
  default = "k3s"
}

resource "aws_instance" "master" {
  ami = data.aws_ami.ubuntu_ami.image_id
  instance_type = var.instance_type
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.security_group.id]
  user_data = <<EOF
#!/bin/bash -xe
# make logs visible in cloudwatch and in log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

my_ip=$(curl http://checkip.amazonaws.com/)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $my_ip" sh
EOF
}

resource "null_resource" "local_setup" {
  triggers = {
    script_change = file("${path.module}/k3s.tf")
    ip = aws_instance.master.public_ip
  }

  provisioner "local-exec" {
    command = <<EOF
      set -e
      mkdir -p ~/.kube
      ssh="ssh -oStrictHostKeyChecking=no ubuntu@${aws_instance.master.public_ip}"
      while ! $ssh sudo k3s kubectl get pods >/dev/null; do
        echo "Waiting for k3s..." >&2
        sleep 1
      done
      $ssh sudo cat /etc/rancher/k3s/k3s.yaml | \
        sed s/127\\.0\\.0\\.1/${aws_instance.master.public_ip}/ >~/.kube/config-${var.kubeconfig_filename_suffix}
      KUBECONFIG=~/.kube/config-${var.kubeconfig_filename_suffix} kubectl get pods >/dev/null
    EOF
  }
}

output "master_ip" {
  value = aws_instance.master.public_ip
}
