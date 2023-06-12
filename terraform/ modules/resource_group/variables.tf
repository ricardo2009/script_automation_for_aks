variables "resource_group" {
    description = "Lista de grupos de recursos"
    type = list(object({
        name = list(string)
        location = string
        ambiente = string
        produto = string
        custom_name = string
    }))
}