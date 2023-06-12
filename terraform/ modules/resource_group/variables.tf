variable "resource_group" {
  description = "Lista de grupos de recursos"
  type        = list(object({
    name      = list(string)
    location  = string
    tags = list(object({
      ambiente  = string
      produto      = string
    }))
  }))
}