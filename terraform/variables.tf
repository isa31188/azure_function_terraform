
variable "project_name" {
  type    = string
  default = "oym-helloworld-sand"
}

variable "location" {
  type    = string
  default = "switzerlandnorth"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "sandbox"
    creator     = "isabel.lafaia@oym.ch"
  }

}