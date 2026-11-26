@tool
extends EditorPlugin

const PLUGIN_TITLE := "GAME LAB Connect"
const REQUEST_TIMEOUT_SECONDS := 8.0

var _dock: PanelContainer
var _url_input: LineEdit
var _token_input: LineEdit
var _connect_button: Button
var _status_label: Label
var _details_label: Label
var _http: HTTPRequest


func _enter_tree() -> void:
	_build_panel()
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)


func _exit_tree() -> void:
	if _http != null:
		_http.cancel_request()
		_http.queue_free()
		_http = null
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _build_panel() -> void:
	_dock = PanelContainer.new()
	_dock.name = PLUGIN_TITLE
	_dock.custom_minimum_size = Vector2(280, 320)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	_dock.add_child(layout)

	var title := Label.new()
	title.text = "GAME LAB CONNECT"
	title.add_theme_font_size_override("font_size", 18)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Conecte este editor ao seu ambiente GAME LAB."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	var project_title := Label.new()
	project_title.text = "PROJETO ABERTO"
	project_title.add_theme_font_size_override("font_size", 12)
	layout.add_child(project_title)

	var project_info := Label.new()
	project_info.text = "Godot " + str(Engine.get_version_info().get("string", "4.x")) + "\n" + ProjectSettings.globalize_path("res://")
	project_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	project_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(project_info)

	var separator := HSeparator.new()
	layout.add_child(separator)

	var endpoint_label := Label.new()
	endpoint_label.text = "ENDEREÇO DO GAME LAB"
	endpoint_label.add_theme_font_size_override("font_size", 12)
	layout.add_child(endpoint_label)

	_url_input = LineEdit.new()
	_url_input.placeholder_text = "https://seu-endpoint-privado"
	_url_input.clear_button_enabled = true
	_url_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_url_input)

	var token_label := Label.new()
	token_label.text = "TOKEN DE ACESSO"
	token_label.add_theme_font_size_override("font_size", 12)
	layout.add_child(token_label)

	_token_input = LineEdit.new()
	_token_input.placeholder_text = "Cole o token privado aqui"
	_token_input.secret = true
	_token_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_token_input)

	_connect_button = Button.new()
	_connect_button.text = "Testar conexão"
	_connect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_button.pressed.connect(_test_connection)
	layout.add_child(_connect_button)

	_status_label = Label.new()
	_status_label.text = "Desconectado"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)

	_details_label = Label.new()
	_details_label.text = "A conexão inicial verifica a ponte autenticada do GAME LAB. Nenhum arquivo do projeto é enviado nesta etapa."
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_details_label)

	var footer := Label.new()
	footer.text = "Fase 1.0 — conexão e diagnóstico"
	footer.add_theme_font_size_override("font_size", 11)
	layout.add_child(footer)


func _test_connection() -> void:
	if _http == null or _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_status_label.text = "Aguarde: já existe uma solicitação em andamento."
		return

	var endpoint := _url_input.text.strip_edges()
	var token := _token_input.text.strip_edges()
	if endpoint.is_empty() or token.length() < 32:
		_status_label.text = "Informe o endereço e um token com pelo menos 32 caracteres."
		return

	if not endpoint.begins_with("https://") and not endpoint.begins_with("http://127.0.0.1") and not endpoint.begins_with("http://localhost"):
		_status_label.text = "Por segurança, use HTTPS. HTTP só é aceito em localhost."
		return

	while endpoint.ends_with("/"):
		endpoint = endpoint.left(endpoint.length() - 1)

	var headers := PackedStringArray([
		"Authorization: Bearer " + token,
		"Accept: application/json"
	])
	_connect_button.disabled = true
	_status_label.text = "Verificando conexão segura..."
	_details_label.text = "Consultando o endpoint /health."
	var error := _http.request(endpoint + "/health", headers, HTTPClient.METHOD_GET)
	if error != OK:
		_connect_button.disabled = false
		_status_label.text = "Não foi possível iniciar a conexão. Código: " + str(error)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_connect_button.disabled = false
	if result != HTTPRequest.RESULT_SUCCESS:
		_status_label.text = "Falha de rede ou TLS. Verifique o endereço e o acesso privado."
		_details_label.text = "Código de transporte: " + str(result)
		return

	if response_code != 200:
		_status_label.text = "O servidor respondeu HTTP " + str(response_code) + "."
		_details_label.text = "Verifique o token e confirme que o endpoint é a ponte GAME LAB."
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_status_label.text = "O servidor respondeu, mas o JSON não é válido."
		_details_label.text = "A resposta não corresponde ao formato esperado."
		return

	_status_label.text = "Conexão estabelecida."
	var details: Array[String] = []
	if parsed.has("status"):
		details.append("Status: " + str(parsed.get("status")))
	if parsed.has("npc_count"):
		details.append("NPCs registrados: " + str(parsed.get("npc_count")))
	if parsed.has("world_minute"):
		details.append("Minuto do mundo: " + str(parsed.get("world_minute")))
	if details.is_empty():
		details.append("Endpoint autenticado respondeu corretamente.")
	_details_label.text = "\n".join(details)
