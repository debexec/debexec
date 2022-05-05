from PySide2.QtWidgets import (QWizard, QWizardPage, QApplication, QVBoxLayout, QHBoxLayout, QLabel, QRadioButton, QWidget, QSpacerItem, QSizePolicy, QProgressBar)
from PySide2.QtCore import (QCoreApplication, Qt, QThread, Signal)
from enum import (IntEnum, auto)
from threading import (Lock)
from select import (select)

import sys
import os

class FifoThread(QThread):
    new_msg = Signal(str)
    _fifo = None
    
    def __init__(self, fifo):
        super().__init__()
        self._fifo_filename = fifo
        self._isRunning = True
        self._lock = Lock()

    def _run(self):
        fifo, _, _ = select([self._fifo],[],[self._fifo])
        if len(fifo) == 0: return
        fifo = fifo[0]
        for data in self._fifo:
            self.new_msg.emit(data)
        self._fifo.flush()
    
    def _quit(self):
        self._isRunning = False
    
    def quit(self):
        self._quit()
        with self._lock: pass
        if self._fifo is not None: self._fifo.close()
        os.remove(self._fifo_filename)
    
    def run(self):
        self._fifo = open(self._fifo_filename, 'r')
        with self._lock:
            while self._isRunning:
                self._run()

class StartupPage(QWizardPage):
    def __init__(self, parent):
        super().__init__(parent)
        self.setTitle("Please Stand By")
        self.setSubTitle("Starting up...")
    
    def isComplete(self):
        return False

class WrapLayout(QWidget):
    def __init__(self, layout):
        super().__init__()
        self.setLayout(layout)

class PermissionsPage(QWizardPage):
    def __init__(self, parent):
        super().__init__(parent)
        self.setTitle("System Permissions")
        self.setSubTitle("")
        layout = QVBoxLayout()
        message = QLabel('This application is requesting permissions to the following system services:')
        message.setWordWrap(True)
        layout.addWidget(message)
        self._access = access = QLabel('[]')
        access.setWordWrap(True)
        layout.addWidget(access)
        message = QLabel('Grant access to these services?')
        message.setWordWrap(True)
        layout.addWidget(message)
        response = QHBoxLayout()
        self._response = [None, None]
        self._response[0] = QRadioButton('No', self)
        self._response[0].setChecked(True)
        response.addWidget(self._response[0])
        self._response[1] = QRadioButton('Yes', self)
        self.registerField('allow-access', self._response[1])
        response.addWidget(self._response[1])
        layout.addWidget(WrapLayout(response))
        layout.addItem(QSpacerItem(0, 0, QSizePolicy.Expanding, QSizePolicy.Expanding))
        message = QLabel('(Some applications may fail to function without granting access.)')
        message.setWordWrap(True)
        layout.addWidget(message)
        self.setLayout(layout)
    
    def setAccess(self, access):
        self._access.setText(access)
    
    def isComplete(self):
        return True

class LaunchingPage(QWizardPage):
    def __init__(self, parent):
        super().__init__(parent)
        self.setTitle("Please Stand By")
        self.setSubTitle("Launching...")
    
    def isComplete(self):
        return False

class DownloadPage(QWizardPage):
    def __init__(self, parent):
        super().__init__(parent)
        self.setTitle("Downloading Dependencies")
        self.setSubTitle("Downloading...")
        layout = QVBoxLayout()
        progress = self.progress = QProgressBar()
        layout.addWidget(progress)
        self.setLayout(layout)
    
    def isComplete(self):
        return False

def apt_progress(parent, margins=None):
    layout = QVBoxLayout()
    if margins is not None:
        layout.setContentsMargins(margins, margins, margins, margins)
    message = parent.upstatus = QLabel()
    layout.addWidget(message)
    progress = parent.upprogress = QProgressBar()
    layout.addWidget(progress)
    message = parent.dlstatus = QLabel()
    layout.addWidget(message)
    progress = parent.dlprogress = QProgressBar()
    layout.addWidget(progress)
    message = parent.pmstatus = QLabel()
    layout.addWidget(message)
    progress = parent.pmprogress = QProgressBar()
    layout.addWidget(progress)
    return layout

class InstallCorePage(QWizardPage):
    def __init__(self, parent):
        super().__init__(parent)
        self.setTitle("Installing Core Utilities")
        self.setSubTitle("")
        layout = QVBoxLayout()
        message = self.custatus = QLabel()
        layout.addWidget(message)
        progress = self.cuprogress = QProgressBar()
        layout.addWidget(progress)
        layout.addWidget(WrapLayout(apt_progress(self, margins=0)))
        self.setLayout(layout)
    
    def isComplete(self):
        return False

class InstallAppPage(QWizardPage):
    def __init__(self, parent):
        super().__init__(parent)
        self.setTitle("Installing Application Dependencies")
        self.setSubTitle("")
        layout = apt_progress(self)
        self.setLayout(layout)
    
    def isComplete(self):
        return False

class PAGE(IntEnum):
    STARTUP = auto()
    PERMISSIONS = auto()
    DOWNLOAD = auto()
    INSTALLCORE = auto()
    INSTALLAPP = auto()
    LAUNCHING = auto()

class DebexecWizard(QWizard):
    def __init__(self):
        super().__init__()
        i=0
        self.setPage(PAGE.STARTUP, StartupPage(parent=self))
        self.setPage(PAGE.PERMISSIONS, PermissionsPage(parent=self))
        self.setPage(PAGE.DOWNLOAD, DownloadPage(parent=self))
        self.setPage(PAGE.INSTALLCORE, InstallCorePage(parent=self))
        self.setPage(PAGE.INSTALLAPP, InstallAppPage(parent=self))
        self.setPage(PAGE.LAUNCHING, LaunchingPage(parent=self))
        self.rejected.connect(self._rejected)
    
    def _rejected(self):
        self.send_msg('DEBEXEC_GUI=0')
    
    def validateCurrentPage(self):
        if self.currentId() == PAGE.PERMISSIONS:
            ALLOW_ACCESS='yes' if self.field('allow-access') else 'no'
            self.send_msg(f"ALLOW_ACCESS={ALLOW_ACCESS}")
        return True
    
    def cli_msg(self, data):
        new_variables = []
        for line in data.split('\n'):
            tmp = line.split('=')
            if len(tmp) != 2: continue
            variable = tmp[0]
            value = tmp[1]
            globals()[variable] = value
            new_variables.append(variable)
        if 'DEBEXEC_EXIT' in new_variables:
            self.accept()
        if 'DEBEXEC_LAUNCH' in new_variables:
            self.setWindowTitle(f'Debian Packaged Executable - {DEBEXEC_LAUNCH}')
            self.send_msg(f'DEBEXEC_GUI=1')
        if 'DEBEXEC_ACCESS' in new_variables:
            self.page(PAGE.PERMISSIONS).setAccess(DEBEXEC_ACCESS)
            self.setStartId(PAGE.PERMISSIONS)
            self.restart()
        if 'DEBEXEC_DOWNLOADSTEP' in new_variables and DEBEXEC_DOWNLOADSTEP == 0:
            self.setStartId(PAGE.DOWNLOAD)
            self.restart()
        if 'DEBEXEC_DOWNLOADSTEPS' in new_variables:
            self.page(PAGE.DOWNLOAD).progress.setMaximum(int(DEBEXEC_DOWNLOADSTEPS))
        if 'DEBEXEC_DOWNLOADSTEP' in new_variables:
            self.page(PAGE.DOWNLOAD).progress.setValue(int(DEBEXEC_DOWNLOADSTEP))
        if 'DEBEXEC_DOWNLOAD' in new_variables:
            self.page(PAGE.DOWNLOAD).setSubTitle(f'Downloading {DEBEXEC_DOWNLOAD}...')
        if 'DEBEXEC_INSTALLCORE' in new_variables:
            self.setStartId(PAGE.INSTALLCORE)
            self.restart()
        if 'DEBEXEC_INSTALLAPP' in new_variables:
            self.setStartId(PAGE.INSTALLAPP)
            self.restart()
    
    def apt_msg(self, data):
        status, *status_fields = data.split(':')
        if status == 'destatus':
            self._mode = int(status_fields[0])
        if status == 'dlstatus':
            self.page(self.currentId()).upstatus.setText(f'Database Updates Downloaded.')
            self.page(self.currentId()).upprogress.setValue(100)
        if status == 'pmstatus':
            self.page(self.currentId()).dlstatus.setText(f'All Files Downloaded.')
        if status == 'dlstatus' or status == 'pmstatus' or status == 'custatus':
            mode = status[0:2] if self._mode != 0 else 'up'
            if mode == 'up' and self.currentId() == PAGE.INSTALLCORE:
                self.page(self.currentId()).custatus.setText(f'Core Utilities Installed.')
            pkg, percent, description = status_fields
            description = description.replace('\n', '')
            status_widget = getattr(self.page(self.currentId()), f'{mode}status')
            status_widget.setText(f'{description}...')
            progress_widget = getattr(self.page(self.currentId()), f'{mode}progress')
            progress_widget.setMaximum(100)
            progress_widget.setValue(float(percent))

def _send_msg(_fifo, msg):
    fifo = open(_fifo, 'w')
    fifo.write(msg)
    fifo.close()

def main():
    QCoreApplication.setOrganizationName('debexec')
    QCoreApplication.setApplicationName('Debian Packaged Executable')
    app = QApplication(sys.argv)
    window = DebexecWizard()
    window.show()
    window.send_msg = lambda msg, _fifo=sys.argv[2]: _send_msg(_fifo, msg)
    cli_thread = FifoThread(sys.argv[1])
    cli_thread.new_msg.connect(window.cli_msg)
    cli_thread.start()
    apt_thread = FifoThread(sys.argv[3])
    apt_thread.new_msg.connect(window.apt_msg)
    apt_thread.start()
    app.exec_()
    cli_thread.quit()
    apt_thread.quit()
    sys.exit(0)

if __name__ == '__main__':
    main()
