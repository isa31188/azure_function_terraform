#variable "owner" {
#  type = string
#  default = "niels"
#}

variable "project_name" {
  type    = string
  default = "oym-sand-helloworld"
}

variable "location" {
  type    = string
  default = "switzerlandnorth"
}

variable "tags" {
  type = map(string)
  default = {
    creator     = "isabel.lafaia@oym.ch"
    environment = "sand"
  }
}