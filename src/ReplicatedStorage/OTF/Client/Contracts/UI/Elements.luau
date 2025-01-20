export type selectItem = {
	value: string,
	image: number?,
	text: string?
} 

export type option_color = "bg_primary"
	| "bg_selected"
	| "bg_unselected"
	| "txt_primary"
	| "txt_unselected"
export type option_udim = "padding"
export type option_number = "font_size"
export type option_font = "font_primary"


return {
	viewport = {}	
} :: {
	viewport: {
		create_asset: (asset: string) -> ViewportFrame,
	},
	style_push: () -> (),
	style_pop: () -> (),
	style_set_color: (option: option_color, color: Color3) -> (),
	style_set_udim: (option: option_udim, udim: UDim) -> (),
	style_set_number: (option: option_number, number: number) -> (),
	style_set_font: (option: option_font, font: Enum.Font) -> (),
	
	create_texture: (parent: GuiBase?) -> CanvasGroup,
	create_frame: (parent: GuiBase?, size: UDim2?, position: UDim2?) -> Frame,
	create_text: (parent: GuiBase?, text: string, color: option_color?) -> TextLabel,
	create_pill: (parent: GuiBase?, text: string, maxDir: ("x" | "y")?) -> GuiObject,
	create_button: (parent: GuiBase?) -> TextButton,
	create_list: (parent: GuiBase?, padding: UDim, direction: Enum.FillDirection?) -> GuiObject,
	create_grid: (parent: GuiBase?, padding: UDim?) -> Frame,
	create_image: (parent: GuiBase?, id: number) -> ImageLabel,
	create_radio: (parent: GuiBase?, callback: (string) -> (), options: {selectItem}) -> GuiObject,
	create_element_sequence: (parent: GuiBase?, ...(string|number|Color3)) -> (Frame, ...GuiObject),
	create_stat: (parent: GuiBase?, name: string) -> GuiObject,
	clear: (instance: GuiBase) -> (),

	on_click: (instance: GuiBase, () -> ()) -> (),
	on_press: (instance: GuiBase, (rel_x: number, rel_y: number) -> ()) -> (),
	
	style_corner: (instance: GuiObject, roundness: UDim?) -> (),
	style_border: (instance: GuiObject, color: Color3, thickness: number) -> (),
	style_line_height: (instance: GuiObject) -> ()
}