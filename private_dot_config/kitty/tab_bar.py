# Custom kitty tab bar: pill tabs with process icons, plus a right-aligned status
# cluster (layout, window count, clock). Catppuccin Macchiato palette.
from datetime import datetime

import subprocess
import sys

from kitty.boss import get_boss
from kitty.fast_data_types import (
    GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS, GLFW_RELEASE, Screen, add_timer, current_focused_os_window_id, get_options,
    get_os_window_size, get_tab_being_dragged, remove_timer, set_tab_being_dragged,
    toggle_maximized,
)
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title
from kitty.utils import color_as_int

# -- palette -----------------------------------------------------------------
BASE = as_rgb(0x24273A)
MANTLE = as_rgb(0x1E2030)
SURFACE0 = as_rgb(0x363A4F)
SURFACE1 = as_rgb(0x494D64)
TEXT = as_rgb(0xCAD3F5)
SUBTEXT0 = as_rgb(0xA5ADCB)
OVERLAY0 = as_rgb(0x6E738D)
MAUVE = as_rgb(0xC6A0F6)
LAVENDER = as_rgb(0xB7BDF8)
PEACH = as_rgb(0xF5A97F)
YELLOW = as_rgb(0xEED49F)
GREEN = as_rgb(0xA6DA95)
SAPPHIRE = as_rgb(0x7DC4E4)
RED = as_rgb(0xED8796)

LEFT = chr(0xE0B6)
RIGHT = chr(0xE0B4)

# Icon by the active window's executable name (Nerd Font codepoints as chr()
# so the glyphs survive tooling that strips private-use characters).
_SH, _VIM, _NVIM, _PY = chr(0xE795), chr(0xE62B), chr(0xE6AE), chr(0xE73C)
_NODE, _RUST, _GO, _C = chr(0xE718), chr(0xE7A8), chr(0xE626), chr(0xE61E)
_DOCKER, _K8S, _GIT, _MON = chr(0xE7B0), chr(0xF10FE), chr(0xE702), chr(0xF0E4)
_COG, _DOC, _DIR, _SSH = chr(0xF0493), chr(0xF0219), chr(0xF024B), chr(0xF0318)
ICONS = {
    'fish': chr(0xF023A), 'zsh': _SH, 'bash': _SH, 'nu': _SH,
    'nvim': _NVIM, 'vim': _VIM, 'vi': _VIM, 'hx': _VIM, 'micro': _VIM,
    'claude': chr(0x2726), 'ssh': _SSH, 'mosh': _SSH,
    'python': _PY, 'python3': _PY, 'node': _NODE, 'bun': _NODE, 'deno': _NODE,
    'cargo': _RUST, 'rustc': _RUST, 'go': _GO, 'gcc': _C, 'make': _C,
    'docker': _DOCKER, 'podman': _DOCKER, 'distrobox': _DOCKER, 'kubectl': _K8S,
    'git': _GIT, 'lazygit': _GIT, 'gh': _GIT,
    'htop': _MON, 'btop': _MON, 'top': _MON,
    'journalctl': _COG, 'systemctl': _COG,
    'less': _DOC, 'bat': _DOC, 'man': _DOC,
    'yazi': _DIR, 'ranger': _DIR, 'nnn': _DIR, 'lf': _DIR,
}
DEFAULT_ICON = chr(0xF120)
I_SPLITS, I_STACK, I_WIN, I_CLOCK, I_CAL, I_DOT = chr(0xF0570), chr(0xF0328), chr(0xF2D2), chr(0xF0150), chr(0xF00ED), chr(0x25CF)

# kitty runs this file afresh for every OS window's tab bar (and on config
# reload), so anything shared lives on one dict attached to kitty.tab_bar. Each
# run takes over the mouse hook and timer, so edits apply on reload.
import kitty.tab_bar as _ktb
_S: dict = _ktb.__dict__.setdefault('_bingham_tab_bar_state', {})
if _S.get('timer') is not None:
    remove_timer(_S['timer'])
_S['timer'] = None
_S['hooked'] = False
_active_tab_data = None

# ── Window controls in the tab bar ─────────────────────────────────────────
# A grouped pill [ min | max | close ] at the right end. Cell ranges are recorded
# while drawing; a hook on TabManager.handle_tab_bar_mouse turns clicks on those
# cells into window actions, and a press-and-drag on empty tab bar space asks
# KWin to start an interactive window move (the tab bar acts as a title bar).
# Kitty exposes no Wayland minimise, and no "is maximised" flag, so minimise goes
# through kdotool and maximised state is inferred from window size vs work area.
I_MIN, I_MAX, I_RESTORE, I_CLOSE = chr(0xF05B0), chr(0xF05AF), chr(0xF05B2), chr(0xF0156)
# macOS keeps its native title bar (macos.conf), so none of this runs there.
WINDOW_CONTROLS = sys.platform != 'darwin'
_buttons: dict[int, list[tuple[int, int, str]]] = _S.setdefault('buttons', {})
_press: dict[int, tuple[float, float] | None] = _S.setdefault('press', {})
DRAG_PX = 8


def _is_maximized(os_window_id: int) -> bool:
    # Work areas come back in physical pixels and include panels, window sizes
    # are logical, so compare the framebuffer and allow a panel's worth of height.
    try:
        from kitty.fast_data_types import glfw_get_monitor_workarea
        sz = get_os_window_size(os_window_id)
        if not sz:
            return False
        w, h = sz['framebuffer_width'], sz['framebuffer_height']
        for area in glfw_get_monitor_workarea() or ():
            aw, ah = area[2], area[3]
            if aw and ah and w >= aw - 4 and h >= ah * 0.9:
                return True
    except Exception:
        pass
    return False


def _do_button(tm, name: str) -> None:
    boss = get_boss()
    if name == 'close':
        boss.confirm_os_window_close(tm.os_window_id)
    elif name == 'max':
        toggle_maximized(tm.os_window_id)
        tm.mark_tab_bar_dirty()
    elif name == 'min':
        try:
            subprocess.Popen(['kdotool', 'getactivewindow', 'windowminimize'],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError:
            pass


def _start_window_move() -> None:
    try:
        subprocess.Popen(['qdbus6', 'org.kde.kglobalaccel', '/component/kwin',
                          'org.kde.kglobalaccel.Component.invokeShortcut', 'Window Move'],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def _cell_at(tm, x: float, y: float) -> tuple[int, int] | None:
    tb = tm.tab_bar
    if not getattr(tb, 'laid_out_once', False):
        return None
    g = tb.window_geometry
    if not (g.left <= x < g.right and g.top <= y < g.bottom):
        return None
    return int(x - g.left) // tb.cell_width, int(y - g.top) // tb.cell_height


def _button_at(tm, x: float, y: float) -> str | None:
    cell = _cell_at(tm, x, y)
    if cell is None or cell[1] != 0:
        return None
    for start, end, name in _buttons.get(tm.os_window_id, ()):
        if start <= cell[0] <= end:
            return name
    return None


# Kitty only forwards tab-bar motion events to Python while a tab drag is in
# progress, so a press on empty space registers a dummy drag (an id no tab has)
# purely to receive motion. It is cleared on release, on hand-off to KWin, and
# on any later press, so it can never stick.
_FAKE_DRAG_ID = 2 ** 31 - 7


def _install_mouse_hook() -> None:
    if _S['hooked'] or not WINDOW_CONTROLS:
        return
    _S['hooked'] = True
    from kitty.tabs import TabManager
    orig = _S.setdefault('orig_mouse', TabManager.handle_tab_bar_mouse)

    def handle_tab_bar_mouse(self, x, y, button, modifiers, action):
        osw = self.os_window_id
        if button == -1:  # motion
            p = _press.get(osw)
            if p is not None:
                if get_tab_being_dragged()[0] != _FAKE_DRAG_ID:
                    _press[osw] = None  # something else took over the drag state
                elif abs(x - p[0]) > DRAG_PX or abs(y - p[1]) > DRAG_PX:
                    _press[osw] = None
                    set_tab_being_dragged()
                    _start_window_move()
                return
            return orig(self, x, y, button, modifiers, action)
        if button == GLFW_MOUSE_BUTTON_LEFT:
            if get_tab_being_dragged()[0] == _FAKE_DRAG_ID:
                set_tab_being_dragged()
            name = _button_at(self, x, y)
            if name is not None:
                _press[osw] = None
                if action == GLFW_RELEASE:
                    _do_button(self, name)
                return
            if action == GLFW_PRESS:
                on_tab = self.tab_bar.tab_id_at(int(x), int(y)) != 0
                if on_tab:
                    _press[osw] = None
                else:
                    _press[osw] = (x, y)
                    orig(self, x, y, button, modifiers, action)
                    set_tab_being_dragged(_FAKE_DRAG_ID, False, x, y)
                    return
            elif action == GLFW_RELEASE:
                _press[osw] = None
        return orig(self, x, y, button, modifiers, action)

    TabManager.handle_tab_bar_mouse = handle_tab_bar_mouse


# ── Claude state badges ─────────────────────────────────────────────────────
# ~/.claude/hooks/kitty-status.sh sets the window user var claude_state to busy,
# waiting or done. Each tab shows a badge for its Claude windows: a spinner while
# Claude works, a yellow ? while it needs you, a green tick when it has finished
# (cleared once you focus that window). The 0.25 s tick only repaints when a
# badge changes or a spinner is visible, plus every 20 s for the clock.
CLAUDE_RANK = {'waiting': 3, 'busy': 2, 'done': 1}
SPINNER = '\u280b\u2819\u2839\u2838\u283c\u2834\u2826\u2827\u2807\u280f'
_tick = 0
_last_states: tuple = ()


def _claude_state(boss_tab) -> str:
    best = ''
    for w in boss_tab:
        st = w.user_vars.get('claude_state', '')
        if CLAUDE_RANK.get(st, 0) > CLAUDE_RANK.get(best, 0):
            best = st
    return best


def _redraw(*_):
    global _tick, _last_states
    _tick += 1
    boss = get_boss()
    states = []
    focused = boss.active_window
    for w in boss.window_id_map.values():
        st = w.user_vars.get('claude_state')
        if st == 'done' and w is focused and current_focused_os_window_id() == w.os_window_id:
            w.set_user_var('claude_state', None)
            st = None
        if st:
            states.append((w.id, st))
    states_t = tuple(states)
    busy = any(st == 'busy' for _, st in states)
    if states_t != _last_states or busy or _tick % 80 == 0:
        _last_states = states_t
        for tm in boss.all_tab_managers:
            tm.mark_tab_bar_dirty()


def _ensure_clock_timer():
    if _S['timer'] is None:
        _S['timer'] = add_timer(_redraw, 0.25, True)


def _active_exe(tab: TabBarData) -> str:
    try:
        boss_tab = get_boss().tab_for_id(tab.tab_id)
        aw = boss_tab.active_window if boss_tab else None
        if aw is None:
            return ''
        # The foreground group includes children (MCP servers, language servers),
        # so prefer the first process with a known icon, else the group leader.
        names = [p['cmdline'][0].rsplit('/', 1)[-1] for p in aw.child.foreground_processes if p.get('cmdline')]
        return next((n for n in names if n in ICONS), names[0] if names else '')
    except Exception:
        return ''


def _draw_pill(screen: Screen, text: str, fg: int, bg: int, outer_bg: int) -> None:
    screen.cursor.fg = bg
    screen.cursor.bg = outer_bg
    screen.draw(LEFT)
    screen.cursor.fg = fg
    screen.cursor.bg = bg
    screen.draw(text)
    screen.cursor.fg = bg
    screen.cursor.bg = outer_bg
    screen.draw(RIGHT)


def _draw_status(screen: Screen, tab: TabBarData, outer_bg: int) -> None:
    now = datetime.now()
    items = []
    layout = (tab.layout_name or '').replace('splits', I_SPLITS + ' splits').replace('stack', I_STACK + ' stack')
    if layout:
        items.append((layout, SUBTEXT0, SURFACE0))
    if tab.num_windows > 1:
        items.append((f'{I_WIN} {tab.num_windows}', LAVENDER, SURFACE0))
    items.append((I_CLOCK + now.strftime(' %H:%M'), BASE, MAUVE))
    items.append((I_CAL + now.strftime(' %a %d %b'), SUBTEXT0, SURFACE0))

    # Window controls: one rounded pill [ min | max | close ] at the far right.
    buttons = []
    if WINDOW_CONTROLS:
        maximized = _is_maximized(tab.os_window_id)
        buttons = [('min', I_MIN, SUBTEXT0, SURFACE0), ('max', I_RESTORE if maximized else I_MAX, SUBTEXT0, SURFACE0), ('close', I_CLOSE, BASE, RED)]
    btn_width = 2 + 1 + len(buttons) * 3 + 1 + 1 if buttons else 0  # spacer, left cap, segments, right cap, margin
    width = sum(len(t) + 2 for t, _, _ in items) + (len(items) - 1)
    start = screen.columns - width - btn_width - 1
    if start <= screen.cursor.x + 1:
        return
    screen.cursor.bg = outer_bg
    screen.draw(' ' * (start - screen.cursor.x))
    for i, (text, fg, bg) in enumerate(items):
        if i:
            screen.cursor.bg = outer_bg
            screen.draw(' ')
        _draw_pill(screen, text, fg, bg, outer_bg)
    if not buttons:
        screen.cursor.bg = outer_bg
        screen.draw(' ')
        return
    screen.cursor.bg = outer_bg
    screen.draw('  ')
    ranges = []
    screen.cursor.fg = buttons[0][3]
    screen.cursor.bg = outer_bg
    screen.draw(LEFT)
    for name, glyph, fg, bg in buttons:
        bstart = screen.cursor.x
        screen.cursor.fg = fg
        screen.cursor.bg = bg
        screen.draw(' ' + glyph + ' ')
        ranges.append((bstart, screen.cursor.x - 1, name))
    screen.cursor.fg = buttons[-1][3]
    screen.cursor.bg = outer_bg
    screen.draw(RIGHT)
    _buttons[tab.os_window_id] = ranges
    screen.cursor.bg = outer_bg
    screen.draw(' ')


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData, before: int,
    max_title_length: int, index: int, is_last: bool, extra_data: ExtraData,
) -> int:
    global _active_tab_data
    _ensure_clock_timer()
    _install_mouse_hook()
    if tab.is_active:
        _active_tab_data = tab
    outer_bg = as_rgb(color_as_int(draw_data.default_bg))

    if tab.is_active:
        fg, bg, idx_fg = BASE, MAUVE, as_rgb(0x5B3F7A)
    elif tab.needs_attention:
        fg, bg, idx_fg = BASE, YELLOW, SURFACE1
    elif tab.has_activity_since_last_focus:
        fg, bg, idx_fg = TEXT, SURFACE1, PEACH
    else:
        fg, bg, idx_fg = SUBTEXT0, SURFACE0, OVERLAY0

    if screen.cursor.x == 0:
        screen.cursor.bg = outer_bg
        screen.draw(' ')

    exe = _active_exe(tab)
    icon = ICONS.get(exe, DEFAULT_ICON)

    screen.cursor.fg = bg
    screen.cursor.bg = outer_bg
    screen.draw(LEFT)
    screen.cursor.bg = bg
    screen.cursor.fg = idx_fg
    screen.cursor.bold = True
    screen.draw(f'{index} ')
    screen.cursor.bold = False
    screen.cursor.fg = fg
    screen.draw(f'{icon} ')
    draw_title(draw_data, screen, tab, index, max_title_length)
    boss_tab = get_boss().tab_for_id(tab.tab_id)
    st = _claude_state(boss_tab) if boss_tab else ''
    if st:
        badge_fg = {'busy': PEACH, 'waiting': YELLOW, 'done': GREEN}[st]
        if tab.is_active:
            badge_fg = BASE
        screen.cursor.fg = badge_fg
        screen.draw(' ' + {'busy': SPINNER[_tick % len(SPINNER)], 'waiting': '?', 'done': '\u2713'}[st])
    if tab.has_activity_since_last_focus and not tab.is_active:
        screen.cursor.fg = PEACH
        screen.draw(' \u25cf')
    screen.cursor.fg = fg
    screen.cursor.bg = bg
    screen.draw(' ')
    screen.cursor.fg = bg
    screen.cursor.bg = outer_bg
    screen.draw(RIGHT)
    screen.cursor.bg = outer_bg
    screen.draw(' ')
    end = screen.cursor.x

    if is_last:
        _draw_status(screen, _active_tab_data or tab, outer_bg)
    return end
