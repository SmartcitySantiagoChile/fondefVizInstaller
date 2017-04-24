import sys
import os

def processWSGIFile(projectPath, projectName):

    wsgiDirPath = '{}/{}'.format(projectPath, projectName)
    wsgiFilePath = '{}/wsgi.py'.format(wsgiDirPath)
    FILE = open(wsgiFilePath,'r')
 
    newLine = []
 
    for line in FILE:
         if "sys.path.append" in line:
             newLine.append('sys.path.append(\'' +wsgiDirPath + '\')\n')
         else:
             newLine.append(line)

    FILE.close()

    # rewrite file
    FILE = open(wsgiFilePath,'w')
    for line in newLine:
        FILE.write(line)
    FILE.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        pass
    else: 
        projectPath =  sys.argv[1]
        projectName = sys.argv[2]

        processWSGIFile(projectPath, projectName)
