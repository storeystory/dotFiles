# ── ble.sh config ────────────────────────────────────────────────────
bleopt prompt_ps1_final=''

# Syntax highlighting colors
ble-color-setface syntax_default        fg=#d8cab8
ble-color-setface syntax_command        fg=#AC82E9,bold
ble-color-setface syntax_quoted         fg=#a8d8a8
ble-color-setface syntax_quotation      fg=#a8d8a8
ble-color-setface syntax_escape         fg=#fcb167
ble-color-setface syntax_expr           fg=#7b91fc
ble-color-setface syntax_error          fg=#fc4649,bold
ble-color-setface syntax_varname        fg=#d8cab8
ble-color-setface syntax_delimiter      fg=#8a7d6e

# Auto-suggestion color
ble-color-setface auto_complete         fg=#4a4050

# Completion menu
ble-color-setface menu_desc_default     fg=#8a7d6e,bg=#111014

# Selection
ble-color-setface region_target         fg=#141216,bg=#AC82E9

[[ ${BLE_VERSION-} ]] && ble-attach
