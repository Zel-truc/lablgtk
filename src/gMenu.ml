(* $Id$ *)

open Misc
open Gtk
open GObj
open GCont
open GUtil

(* Menu items *)

class type is_menu = object
  method as_menu : Menu.t obj
end

class item_skel obj = object
  inherit container obj
  method as_item = MenuItem.coerce obj
  method set_submenu : 'a. (#is_menu as 'a) -> unit =
    fun w -> MenuItem.set_submenu obj w#as_menu
  method remove_submenu () = MenuItem.remove_submenu obj
  method configure = MenuItem.configure obj
  method activate () = MenuItem.activate obj
  method right_justify () = MenuItem.right_justify obj
  method add_accelerator =
    Widget.add_accelerator obj sig:MenuItem.Signals.activate
end

class item_signals obj ?:after = object
  inherit GCont.item_signals obj ?:after
  method activate = Signal.connect sig:MenuItem.Signals.activate obj ?:after
end

class item_wrapper obj = object
  inherit item_skel (MenuItem.coerce obj)
  method connect = new item_signals ?obj
end

class item ?:label ?:border_width ?:width ?:height ?:packing =
  let w = MenuItem.create ?None ?:label in
  let () = Container.setter w cont:ignore ?:border_width ?:width ?:height in
  object (self)
    inherit item_wrapper w
    initializer pack_return :packing (self :> item_wrapper)
  end

class tearoff_item ?:border_width ?:width ?:height ?:packing =
  let w = MenuItem.tearoff_create () in
  let () = Container.setter w cont:ignore ?:border_width ?:width ?:height in
  object (self)
    inherit item_wrapper w
    initializer pack_return :packing (self :> item_wrapper)
  end

class check_item_signals obj ?:after = object
  inherit item_signals obj ?:after
  method toggled = Signal.connect sig:CheckMenuItem.Signals.toggled obj ?:after
end

class check_item_skel obj = object
  inherit item_skel obj
  method set_active = CheckMenuItem.set_active obj
  method set_show_toggle = CheckMenuItem.set_show_toggle obj
  method active = CheckMenuItem.get_active obj
  method toggled () = CheckMenuItem.toggled obj
end

class check_item_wrapper obj = object
  inherit check_item_skel (CheckMenuItem.coerce obj)
  method connect = new check_item_signals ?obj
end

class check_item ?:label
    ?:active ?:show_toggle ?:border_width ?:width ?:height ?:packing =
  let w = CheckMenuItem.create ?None ?:label in
  let () =
    CheckMenuItem.setter w cont:ignore ?:active ?:show_toggle;
    Container.setter w cont:ignore ?:border_width ?:width ?:height in
  object (self)
    inherit check_item_wrapper w
    initializer pack_return :packing (self :> check_item_wrapper)
  end

class radio_item_skel obj = object
  inherit check_item_skel obj
  method group = RadioMenuItem.group obj
  method set_group = RadioMenuItem.set_group obj
end

class radio_item_wrapper obj = object
  inherit radio_item_skel (RadioMenuItem.coerce obj)
  method connect = new check_item_signals ?obj
end

class radio_item ?:group ?:label
    ?:active ?:show_toggle ?:border_width ?:width ?:height ?:packing =
  let w = RadioMenuItem.create ?None ?:group ?:label in
  let () =
    CheckMenuItem.setter w cont:ignore ?:active ?:show_toggle;
    Container.setter w cont:ignore ?:border_width ?:width ?:height in
  object (self)
    inherit radio_item_wrapper w
    initializer pack_return :packing (self :> radio_item_wrapper)
  end

(* Menu Shell *)

class menu_shell_signals obj ?:after = object
  inherit container_signals obj ?:after
  method deactivate =
    Signal.connect sig:MenuShell.Signals.deactivate obj ?:after
end

class menu_shell obj = object
  inherit [MenuItem.t,item] item_container obj
  method private wrap w = new item_wrapper (MenuItem.cast w)
  method insert : 'a. (MenuItem.t #is_item as 'a) -> _ =
    fun w -> MenuShell.insert obj w#as_item
  method deactivate () = MenuShell.deactivate obj
  method connect = new menu_shell_signals ?obj
end

(* Menu *)

class menu_wrapper obj = object
  inherit menu_shell (Menu.coerce obj)
  method popup = Menu.popup obj
  method popdown () = Menu.popdown obj
  method as_menu : Menu.t obj = obj
  method set_accel_group = Menu.set_accel_group obj
end

class menu ?:border_width ?:packing =
  let w = Menu.create () in
  let () = may border_width fun:(Container.set_border_width w) in
  object (self)
    inherit menu_wrapper w
    initializer pack_return :packing (self :> menu_wrapper)
  end

(* Option Menu (GtkButton?) *)
(*
class option_menu_wrapper obj = object
  inherit button (OptionMenu.coerce obj)
  method set_menu (menu : menu) = OptionMenu.set_menu obj menu#as_menu
  method get_menu = new menu_wrapper (OptionMenu.get_menu obj)
  method remove_menu () = OptionMenu.remove_menu obj
  method set_history = OptionMenu.set_history obj
end

class option_menu ?:border_width ?:width ?:height ?:packing =
  let w = OptionMenu.create () in
  let () = Container.setter w cont:ignore ?:border_width ?:width ?:height in
  object (self)
    inherit option_menu_wrapper w
    initializer pack_return :packing (self :> option_menu_wrapper)
  end
*)
(* Menu Bar *)

class menu_bar ?:border_width ?:width ?:height ?:packing =
  let w = MenuBar.create () in
  let () = Container.setter w cont:ignore ?:border_width ?:width ?:height in
  object (self)
    inherit menu_shell w
    initializer pack_return :packing (self :> menu_shell)
  end

(* Menu Factory *)

class ['a] factory (menu : 'a)
    ?:accel_group [< Gtk.AccelGroup.create () >]
    ?:accel_mod [< [`CONTROL] >]
    ?:accel_flags [< [`VISIBLE] >] =
  object (self)
    val menu : #menu_shell = menu
    val group = accel_group
    val m = accel_mod
    val flags = accel_flags
    method menu = menu
    method accel_group = group
    method private bind (item : item) ?:key ?:callback =
      menu#append item;
      may key fun:
	(fun key -> item#add_accelerator group :key mod:m :flags);
      may callback fun:(fun callback -> item#connect#activate :callback)
    method add_item :label ?:key ?:callback ?:submenu =
      let item = new item :label in
      self#bind item ?:key ?:callback;
      may (submenu : menu option) fun:item#set_submenu;
      item
    method add_check_item :label ?:active ?:key ?:callback =
      let item = new check_item :label ?:active in
      self#bind (item :> item) ?:key
	?callback:(may_map callback fun:(fun f () -> f item#active));
      item
    method add_radio_item :label ?:group ?:active ?:key ?:callback =
      let item = new radio_item :label ?:group ?:active in
      self#bind (item :> item) ?:key
	?callback:(may_map callback fun:(fun f () -> f item#active));
      item
    method add_separator () = new item packing:menu#append
    method add_submenu :label ?:key =
      let item = new item :label in
      self#bind item ?:key;
      new menu packing:item#set_submenu
end
