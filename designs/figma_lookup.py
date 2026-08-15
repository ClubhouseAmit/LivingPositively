#!/usr/bin/env python3
"""
Fast lookup/manifest helper over figma_full_dump.json.

Builds an in-memory index once (id -> node, text -> node ids, style id ->
name) so repeated lookups don't re-walk the whole node tree from scratch.
The source dump is never modified — this is a read-only derived view,
regenerated fresh on every run. See designs/figma_diff_process.md for the
full audit process this supports.

Usage (CLI):
    python3 designs/figma_lookup.py list-frames
    python3 designs/figma_lookup.py find-text "some hebrew or english substring"
    python3 designs/figma_lookup.py manifest 1660:2020
    python3 designs/figma_lookup.py manifest 1660:2020 --type TEXT       # just text + textStyle
    python3 designs/figma_lookup.py manifest 1660:2020 --decorated-only  # just shapes/buttons/cards
    python3 designs/figma_lookup.py node 1660:2020

Always redirect `manifest` output straight to its own file (pure JSONL) if
you need to reload it — don't concatenate it with `node`'s pretty-printed
JSON or with your own header lines in the same file; that breaks line-by-
line JSON parsing on reload.

Usage (import):
    from figma_lookup import FigmaIndex
    idx = FigmaIndex('figma_full_dump.json')
    node = idx.by_id['1660:2020']
    hits = idx.find_text('תזכורות')
    manifest = idx.manifest('1660:2020')
"""
import sys
import json
import os

DEFAULT_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'figma_full_dump.json')


def color_to_hex(color):
    if not color:
        return None
    r = round(color.get('r', 0) * 255)
    g = round(color.get('g', 0) * 255)
    b = round(color.get('b', 0) * 255)
    a = color.get('a', 1.0)
    hexstr = '#{:02X}{:02X}{:02X}'.format(r, g, b)
    if a < 1.0:
        hexstr += ' @ alpha {:.2f}'.format(a)
    return hexstr


class FigmaIndex:
    def __init__(self, path=DEFAULT_PATH):
        with open(path) as f:
            self.data = json.load(f)
        self.by_id = {}
        self.text_index = {}
        self.style_catalog = {}
        self._build()

    def _build(self):
        for root_id, root in self.data['nodes'].items():
            for style_id, style_info in (root.get('styles') or {}).items():
                self.style_catalog[style_id] = style_info
            self._walk(root['document'])

    def _walk(self, node):
        self.by_id[node['id']] = node
        if node.get('type') == 'TEXT':
            text = (node.get('characters') or '').strip()
            if text:
                self.text_index.setdefault(text, []).append(node['id'])
        for ch in node.get('children', []) or []:
            self._walk(ch)

    def find_text(self, substring):
        """Substring search (case-sensitive) over all TEXT node contents."""
        hits = []
        for text, ids in self.text_index.items():
            if substring in text:
                for nid in ids:
                    hits.append({'id': nid, 'text': text, 'frame': self.owning_frame_name(nid)})
        return hits

    def owning_frame_name(self, node_id):
        """Walk up parent pointers isn't available (Figma JSON has no parent refs),
        so this does a top-level-frame membership scan instead."""
        for root in self.data['nodes'].values():
            for top_child in root['document'].get('children', []) or []:
                if self._contains(top_child, node_id):
                    return top_child.get('name')
        return None

    def _contains(self, node, node_id):
        if node.get('id') == node_id:
            return True
        for ch in node.get('children', []) or []:
            if self._contains(ch, node_id):
                return True
        return False

    def resolve_style(self, style_id):
        info = self.style_catalog.get(style_id)
        return info.get('name') if info else None

    def manifest(self, node_id):
        """Full property manifest for a node and its subtree — see
        designs/figma_diff_process.md Step 1 for the fields this covers."""
        node = self.by_id.get(node_id)
        if node is None:
            return None
        return self._manifest_walk(node)

    def _manifest_walk(self, node):
        out = []
        bb = node.get('absoluteBoundingBox', {}) or {}
        entry = {
            'id': node.get('id'),
            'type': node.get('type'),
            'name': node.get('name'),
            'pos': (bb.get('x'), bb.get('y')),
            'size': (bb.get('width'), bb.get('height')),
            'cornerRadius': node.get('cornerRadius'),
            'strokeWeight': node.get('strokeWeight'),
            'strokeDashes': node.get('strokeDashes'),
        }
        fills = [color_to_hex(f.get('color')) for f in (node.get('fills') or []) if f.get('type') == 'SOLID']
        if fills:
            entry['fills'] = fills
        strokes = [color_to_hex(s.get('color')) for s in (node.get('strokes') or []) if s.get('type') == 'SOLID']
        if strokes:
            entry['strokes'] = strokes
        if node.get('effects'):
            entry['effects'] = [
                {'type': e.get('type'), 'radius': e.get('radius'),
                 'offset': (e.get('offset', {}).get('x'), e.get('offset', {}).get('y')),
                 'color': color_to_hex(e.get('color'))}
                for e in node['effects'] if e.get('visible', True)
            ]
        style_links = node.get('styles') or {}
        if style_links:
            entry['linkedStyles'] = {prop: self.resolve_style(sid) for prop, sid in style_links.items()}
        if node.get('type') == 'TEXT':
            st = node.get('style', {}) or {}
            entry['text'] = node.get('characters', '')
            entry['textStyle'] = {
                'fontFamily': st.get('fontFamily'),
                'fontWeight': st.get('fontWeight'),
                'fontSize': st.get('fontSize'),
                'lineHeightPx': st.get('lineHeightPx'),
                'align': st.get('textAlignHorizontal'),
            }
        out.append(entry)
        for ch in node.get('children', []) or []:
            out.extend(self._manifest_walk(ch))
        return out

    def list_top_level_frames(self, name_prefix=None):
        result = []
        for root in self.data['nodes'].values():
            for child in root['document'].get('children', []) or []:
                if child.get('type') != 'FRAME':
                    continue
                if name_prefix and not child.get('name', '').startswith(name_prefix):
                    continue
                bb = child.get('absoluteBoundingBox', {}) or {}
                result.append({
                    'id': child['id'], 'name': child['name'],
                    'size': (bb.get('width'), bb.get('height')),
                    'childCount': len(child.get('children', []) or []),
                })
        return result


def _main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    idx = FigmaIndex()

    if cmd == 'list-frames':
        prefix = sys.argv[2] if len(sys.argv) > 2 else None
        for f in idx.list_top_level_frames(prefix):
            print(f"{f['name']:25s} id={f['id']:15s} size={f['size']} children={f['childCount']}")
    elif cmd == 'find-text':
        if len(sys.argv) < 3:
            print('usage: find-text <substring>')
            sys.exit(1)
        for hit in idx.find_text(sys.argv[2]):
            print(f"{hit['id']:15s} frame={hit['frame']!s:25s} text={hit['text'][:50]!r}")
    elif cmd == 'manifest':
        if len(sys.argv) < 3:
            print('usage: manifest <node_id> [--type TEXT|FRAME|...] [--decorated-only]')
            sys.exit(1)
        m = idx.manifest(sys.argv[2])
        if m is None:
            print(f'node {sys.argv[2]} not found', file=sys.stderr)
            sys.exit(1)
        type_filter = None
        decorated_only = False
        rest = sys.argv[3:]
        i = 0
        while i < len(rest):
            if rest[i] == '--type' and i + 1 < len(rest):
                type_filter = rest[i + 1]
                i += 2
            elif rest[i] == '--decorated-only':
                decorated_only = True
                i += 1
            else:
                i += 1
        for entry in m:
            if type_filter and entry.get('type') != type_filter:
                continue
            if decorated_only and not (
                entry.get('cornerRadius')
                or entry.get('strokeDashes')
                or (entry.get('fills') and entry.get('type') != 'TEXT')
            ):
                continue
            print(json.dumps(entry, ensure_ascii=False))
    elif cmd == 'node':
        if len(sys.argv) < 3:
            print('usage: node <node_id>')
            sys.exit(1)
        node = idx.by_id.get(sys.argv[2])
        if node is None:
            print(f'node {sys.argv[2]} not found', file=sys.stderr)
            sys.exit(1)
        print(json.dumps(node, ensure_ascii=False, indent=2)[:4000])
    else:
        print(f'unknown command: {cmd}')
        print(__doc__)
        sys.exit(1)


if __name__ == '__main__':
    _main()
