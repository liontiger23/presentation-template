#!/usr/bin/env python3

# Source: https://gist.github.com/retorquere/9053b3dee7b2ce62382e005c73592391

import zipfile
import sys
import re
import xml.etree.ElementTree as ET

namespaces = {
  'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
  'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
  'p': 'http://schemas.openxmlformats.org/presentationml/2006/main',
}

README = """
Pandoc-compatible pptx templates must adhere to the following rules:

- There must be at least 4 slides in the slide masters, named ppt/slideLayouts/slideLayout[1-4].xml. Each of these templates has a number of expected elements to be found under p:sp / p:nvSpPr / p:nvPr
- ppt/slideLayouts/slideLayout1.xml is a title slide, and must:
  - have a p:ph element with type="ctrTitle"
  - have a p:ph element with type="subTitle"
  - have a p:ph element with type="dt"
- ppt/slideLayouts/slideLayout2.xml is a title + content slide, and must:
  - have a p:ph element with type="title"
  - have a p:ph element *without* a type attribute
- ppt/slideLayouts/slideLayout3.xml is a section header slide, and must:
  - have a p:ph element with either type="title" or type="ctrTitle"
- ppt/slideLayouts/slideLayout4.xml is a title + two-content slide, and must:
  - have a p:ph element with type="title"
  - have at least two p:ph elements *without* a type attribute
"""

class SlideLayout:
  def __init__(self, pptx, path, tpe, name):
    self.path = path
    with pptx.open(path) as layout:
      layout = layout.read().decode("utf-8")
      self.layout = ET.fromstring(layout)
      self.parent = {c:p for p in self.layout.iter() for c in p}
    self.errors = 0
    self.warnings = 0

    self.check_metadata(tpe, name)

  def warning(self, msg):
    print(f'warning: {self.path} {msg}')
    self.warnings += 1

  def error(self, msg):
    print(f'error: {self.path} {msg}')
    self.errors += 1

  def find_with_heritage(self, query, heritage):
    nodes = self.layout.iterfind(query, namespaces)
    nodes = [node for node in nodes if self.check_heritage(node, heritage)]
    return nodes

  def check_heritage(self, node, tags):
    tags = tags[:]
    parent = self.parent.get(node, None)
    while parent and len(tags) > 0:
      tag = parent.tag
      for ns, url in namespaces.items():
        tag = tag.replace('{' + url + '}', ns + ':')

      if tags[-1] != tag: break

      tags.pop()
      parent = self.parent.get(parent, None)
    return len(tags) == 0

  def check_metadata(self, tpe, name):
    if 'type' in self.layout.attrib and self.layout.attrib['type'] != tpe:
      print(f'warning: {self.path} is not of type "{tpe}"')
      self.warnings += 1
    if self.layout.find('p:cSld', namespaces).attrib['name'] != name:
      print(f'warning: {self.path} is not named "{name}"')
      self.warnings += 1

class TitleSlideLayout(SlideLayout):
  def __init__(self, pptx):
    super().__init__(pptx, 'ppt/slideLayouts/slideLayout1.xml', 'title', 'Title Slide')

  def check(self):
    heritage = ['p:sp', 'p:nvSpPr', 'p:nvPr']

    for tpe in ['ctrTitle', 'subTitle', 'dt']:
      if len(self.find_with_heritage(f'.//p:ph[@type="{tpe}"]', heritage)) != 1:
        self.error(f'should have a placeholder (p:ph) with type="{tpe}" under {" / ".join(heritage)}')

class ContentSlideLayout(SlideLayout):
  def __init__(self, pptx):
    super().__init__(pptx, 'ppt/slideLayouts/slideLayout2.xml', 'obj', 'Title and Content')

  def check(self):
    heritage = ['p:sp', 'p:nvSpPr', 'p:nvPr']

    for tpe in ['title']:
      if len(self.find_with_heritage(f'.//p:ph[@type="{tpe}"]', heritage)) != 1:
        self.error(f'should have a placeholder (p:ph) with type="{tpe}" under {" / ".join(heritage)}')

    if len([ph for ph in self.find_with_heritage(f'.//p:ph', heritage) if 'type' not in ph]) == 0:
      self.error(f'should have a placeholder (p:ph) under {" / ".join(heritage)} without a type"')

    for tpe in ['body']:
      if len(self.find_with_heritage(f'.//p:ph[@type="{tpe}"]', heritage)) > 0:
        self.warning(f'has body placeholder (p:ph) with type="{tpe}" under {" / ".join(heritage)} (expected no type attribute)')

class SectionSlideLayout(SlideLayout):
  def __init__(self, pptx):
    super().__init__(pptx, 'ppt/slideLayouts/slideLayout3.xml', 'secHead', 'Section Header')

  def check(self):
    heritage = ['p:sp', 'p:nvSpPr', 'p:nvPr']

    nodes = self.find_with_heritage(f'.//p:ph[@type="title"]', heritage) + self.find_with_heritage(f'.//p:ph[@type="ctrTitle"]', heritage)
    if len(nodes) != 1:
      self.error(f'should have a placeholder (p:ph) under {" / ".join(heritage)} with type="title" or "ctrTitle"')

class TwoContentSlideLayout(SlideLayout):
  def __init__(self, pptx):
    super().__init__(pptx, 'ppt/slideLayouts/slideLayout4.xml', 'twoObj', 'Two Content')

  def check(self):
    heritage = ['p:sp', 'p:nvSpPr', 'p:nvPr']

    for tpe in ['title']:
      if len(self.find_with_heritage(f'.//p:ph[@type="{tpe}"]', heritage)) != 1:
        self.error(f'should have a placeholder (p:ph) with @type="{tpe}" under {" / ".join(heritage)}')

    if len([ph for ph in self.find_with_heritage(f'.//p:ph', heritage) if 'type' not in ph]) < 2:
      self.error(f'should have two placeholders (p:ph) without a type under {" / ".join(heritage)}"')

    for tpe in ['body']:
      if len(self.find_with_heritage(f'.//p:ph[@type="{tpe}"]', heritage)) > 0:
        self.warning(f'has body placeholder (p:ph) with type="{tpe}" under {" / ".join(heritage)} (expected no type attribute)')

if __name__ == "__main__":
  with zipfile.ZipFile(sys.argv[1], 'r') as pptx:
    errors = 0
    warnings = 0
    for slide in [TitleSlideLayout(pptx), ContentSlideLayout(pptx), SectionSlideLayout(pptx), TwoContentSlideLayout(pptx) ]:
      slide.check()
      errors += slide.errors
      warnings += slide.warnings
  
    print(f'warnings: {warnings}')
    print(f'errors: {errors}')
    
    if warnings > 0 or errors > 0:
        sys.exit(1)


