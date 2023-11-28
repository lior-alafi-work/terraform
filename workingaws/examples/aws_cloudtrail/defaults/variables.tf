variable "trail_name" {
    type = string
}

variable "encrypt" {
    type = bool
    default = false
}

variable "public_bucket" {
    type = bool
    default = true
}

variable "logging_bucket" {
    type = bool
    default = false
}