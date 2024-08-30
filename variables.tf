variable "access_key" {
 description = "AWS access key: "
 type        = string
 }

 variable "secret_key" {
 description = "AWS secret key: "
 type        = string
 }

 variable "region" {
   description = "AWS Prefered region: "
   type = "string"
   default = "us-east-a1"
 }

 variable "ami" {
 description = "AMI ID: "
 type        = string
 }

 variable "key_name" {
 description = "AWS key name: "
 type        = string
 }