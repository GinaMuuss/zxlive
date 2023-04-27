#     zxlive - An interactive tool for the ZX calculus
#     Copyright (C) 2023 - Aleks Kissinger
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import annotations
from PySide2.QtCore import *
from PySide2.QtWidgets import *
import sys
from qt_material import apply_stylesheet, add_fonts

from .mainwindow import MainWindow

class ZXLive(QApplication):
    """The main ZX Live application

    ...
    """

    def __init__(self) -> None:
        super().__init__(sys.argv)
        self.setApplicationName('ZX Live')
        self.setDesktopFileName('ZX Live')
        self.main_window = MainWindow()

        #Stylesheet
        apply_stylesheet(self, theme='light_blue.xml')
        add_fonts()

        self.lastWindowClosed.connect(self.quit)


def main() -> None:
    """Main entry point for ZX Live"""

    zxl = ZXLive()
    zxl.exec_()
