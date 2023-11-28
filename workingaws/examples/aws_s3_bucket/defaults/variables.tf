variable "bucket_name" {
    type = string
    default = "example"
}

variable "key_name" {
    type = string
    default = "foo"
}

variable "enable_encryption" {
    type = bool
    default = true
}
