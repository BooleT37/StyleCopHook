# -*- coding: utf-8 -*- 

from mercurial import ui
import subprocess
import re
import os
import xml.etree.ElementTree as ET

REPOSITORIES_FILE_NAME = "repositories"

HOOKS_PATH = os.environ.get('HG_HOOKS_PATH')

def check(ui, repo, node, **kwargs):
    if HOOKS_PATH is None:
        ui.warn("HG_HOOKS_PATH environmental variable isn't set, StyleCop cannot be hooked\n" + 
        "Go to your \"hooks\" directory and run Initialize.bat to set this variable\n")
        return 0
    
    #Путь до StyleCopCli. Сейчас он находится в папке с хуком.
    #Если будет смысл в дальнейшем перенести его отдельно - нужно будет сделать новую переменную окружения
    STYLECOP_PATH = HOOKS_PATH + "\\StyleCopCLI"
    
    #имя файла с выводом StyleCop'а.
    #Инициализируем только после того, как убедились, что HOOKS_PATH не None
    OUT_FILE = HOOKS_PATH + "\\out.xml"
        
    #Парсим репозитории в файле repositories
    reps = parseRepositories(HOOKS_PATH + "\\" + REPOSITORIES_FILE_NAME)
    
    #Если нашего репозитория нет в списке - не делаем ничего
    if (reps[repo.root] is None):
        return 0
    
    #Если репозиторий есть в списке, но проверка синтаксиса отключена - 
    #Выводим предупреждение (чтобы не забыли когда-нибудь включить)
    if (reps[repo.root] == "0"):
        ui.warn("StyleCop is disabled for this repository, syntax won't be checked\n")
        return 0
        
    #Получаем repoContext для нашего коммита. В нём лежит, в частности, список файлов в коммите
    ctx = repo[node]
    #Инициализируем новый set, где будем хранить файлы, которые нужно передать в StyleCop
    fileSet = set()
    #Итерируемся по списку файлов в коммите
    for currentFile in ctx.files():
        #Если это не .cs-файл - пропускаем его (TODO: добавить ещё расширения?)
        if re.match('.+\.cs', currentFile) and currentFile in ctx:
            fileSet.add(currentFile)
    #Если ни одного C#-файла не было изменено - выходим
    if len(fileSet) == 0:
        return 0
        
    #Подгружаем файл настроек только если он существует
    settingsFile = repo.root + "\Settings.StyleCop"
    settingsString = " -set " + settingsFile if os.path.isfile(settingsFile) else ""
    
    #Инициализируем строку для запуска 
    cmd = STYLECOP_PATH + "\\StyleCopCLI.exe -out " + OUT_FILE + settingsString + " -cs \"" + "\", \"".join(fileSet) + "\""
    ui.status("[StyleCop]:")
    process = subprocess.Popen(cmd)
    process.wait()
    if process.returncode == 2:
        ui.warn(parseXml(OUT_FILE))
    elif process.returncode == 1:
        ui.warn("Error while executing StyleCop syntax check\n")

    return process.returncode
    
def parseXml(file):
    MAX_COUNT = 10
    ret = ""
    tree = ET.parse(file)
    root = tree.getroot()
    ret += str(len(root)) + " StyleCop violations found:\n"
    count = 1
    hasMoreViolations = False
    for child in root:
        ret += "    " + str(count) + ": " + child.attrib["Source"] + " [line " + child.attrib["LineNumber"] + "]:\n" + "    " + child.text + "\n"
        count += 1
        if count > MAX_COUNT:
            hasMoreViolations = True
            break
    if hasMoreViolations:
        ret+= "    ...\n"
    ret += "\n"
    return ret
    
def parseRepositories(fileName):
    reps = {}
    f = open(fileName, 'r')
    for line in f:
        parts = line.split("=")
        repoName = parts[0].strip()
        repoStatus = "1" if len(parts) == 1 else parts[1].strip()
        reps[repoName] = repoStatus
    return reps