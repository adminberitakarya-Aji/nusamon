class_name ThemeUI
extends RefCounted
## Tema UI terpusat NUSAMON (static) — UI pass 1 (Fase 5).
## Warna & style konsisten untuk battle & world scene: panel membulat,
## tombol dengan hover, HP bar dinamis, chip tipe berwarna (11 tipe).
## Palet: tropis GDD §7 — hijau rimba, biru samudra, oranye senja.

const PANEL_BG := Color(0.07, 0.1, 0.13, 0.94)
const PANEL_BORDER := Color(0.25, 0.45, 0.38, 0.8)
const AKSEN := Color(0.95, 0.75, 0.3)        # aksen emas (judul/hp text)
const HIJAU := Color(0.2, 0.68, 0.35)
const HIJAU_TOMBOL := Color(0.13, 0.42, 0.3)
const HIJAU_TOMBOL_HOVER := Color(0.18, 0.56, 0.4)
const HIJAU_TOMBOL_TEKAN := Color(0.1, 0.32, 0.23)
const LANGIT_ATAS := Color(0.35, 0.62, 0.82)
const LANGIT_CAKRAWALA := Color(0.9, 0.76, 0.58)

const WARNA_TIPE := {
	"Api": Color(0.92, 0.45, 0.18),
	"Air": Color(0.22, 0.52, 0.9),
	"Daun": Color(0.32, 0.75, 0.3),
	"Tanah": Color(0.62, 0.45, 0.25),
	"Udara": Color(0.55, 0.78, 0.95),
	"Normal": Color(0.6, 0.6, 0.55),
	"Listrik": Color(0.95, 0.82, 0.2),
	"Racun": Color(0.7, 0.35, 0.8),
	"Petarung": Color(0.8, 0.35, 0.3),
	"Naga": Color(0.3, 0.45, 0.75),
	"Baja": Color(0.55, 0.62, 0.72),
}


static func warna_tipe(tipe: String) -> Color:
	return WARNA_TIPE.get(tipe, Color(0.55, 0.55, 0.5))


## Warna HP bar berdasarkan rasio HP tersisa (hijau → kuning → merah).
static func hp_warna(rasio: float) -> Color:
	if rasio > 0.5:
		return Color(0.25, 0.8, 0.35)
	if rasio > 0.25:
		return Color(0.95, 0.78, 0.25)
	return Color(0.9, 0.3, 0.25)


# ------------------------------------------------------------ StyleBox

static func panel_style(bg := PANEL_BG, radius := 10, border := PANEL_BORDER) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(radius)
	st.border_color = border
	st.set_border_width_all(1)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	return st


## Terapkan tema panel (bg + border) ke PanelContainer.
static func terapkan_panel(p: PanelContainer, bg := PANEL_BG,
		border := PANEL_BORDER) -> void:
	p.add_theme_stylebox_override("panel", panel_style(bg, 10, border))


## Terapkan tema tombol (normal/hover/pressed/disabled) dengan warna aksen.
static func terapkan_tombol(b: Button, warna := HIJAU_TOMBOL) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = warna
	normal.set_corner_radius_all(8)
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := StyleBoxFlat.new()
	hover.bg_color = HIJAU_TOMBOL_HOVER
	hover.set_corner_radius_all(8)
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = HIJAU_TOMBOL_TEKAN
	pressed.set_corner_radius_all(8)
	pressed.content_margin_top = 6
	pressed.content_margin_bottom = 6
	var mati := StyleBoxFlat.new()
	mati.bg_color = Color(warna.r * 0.5, warna.g * 0.5, warna.b * 0.5, 0.6)
	mati.set_corner_radius_all(8)
	mati.content_margin_top = 6
	mati.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", mati)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", Color(0.95, 0.97, 0.9))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.65, 0.6))
	b.add_theme_font_size_override("font_size", 15)


## Terapkan tema ProgressBar: track gelap + fill berwarna (bisa diubah runtime).
static func bar_style(bar: ProgressBar, warna_fill := HIJAU,
		ukuran := Vector2(240, 18)) -> void:
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = ukuran
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.05, 0.07, 0.09, 0.9)
	track.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = warna_fill
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


## Ubah warna fill bar runtime (rasio HP).
static func warna_fill(bar: ProgressBar, warna: Color) -> void:
	var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
	if fill != null:
		fill.bg_color = warna


## Chip tipe berwarna (RichTextLabel bbcode) — tambah ke parent, kembalikan node.
static func chip_tipe(parent: Control, tipe: String) -> RichTextLabel:
	var c := Color(WARNA_TIPE.get(tipe, Color(0.55, 0.55, 0.5)))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.custom_minimum_size = Vector2(0, 22)
	r.text = "[bgcolor=#%s][color=#ffffff]  %s  [/color][/bgcolor]" % [
		c.to_html(false), tipe]
	parent.add_child(r)
	return r


## Kosongkan container chip lalu isi ulang dari daftar tipe.
static func isi_chip_tipe(container: Control, tipes: Array) -> void:
	for c in container.get_children():
		c.queue_free()
	for t in tipes:
		chip_tipe(container, String(t))
