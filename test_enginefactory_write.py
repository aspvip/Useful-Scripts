import re
import shutil
import codecs
# from lxml import etree
# Backup EngineFactory.xml before making changes
shutil.copy2('/root/scripts/EngineFactory.xml',
             '/root/scripts/EngineFactory.xml.backup')
# EngineFactory engine moduleinfo block

xml_block = """
	      <Moduleinfo>
                       <ModuleID>{module_id}</ModuleID>
                       <POA>POA_VAEngine</POA>
                       <NamingServiceContext>
                                   <Level>CreativeVirtual</Level>
                                   <Level>{module_id}</Level>
                       </NamingServiceContext>
                       <BatchFileName>{engine_name}_VAServer.sh</BatchFileName>
                       <ModuleLoadTime>5</ModuleLoadTime>
              </Moduleinfo>\n"""
module_id = 'Test_Engine2'
engine_name = 'TestEngine2'
# Read EngineFactory.xml
try:
    ef_config = '/root/scripts/EngineFactory.xml'
    f = codecs.open(ef_config, 'r', 'utf-16')
    data = f.read()
except IOError, e:
    print e
finally:
    f.close()

# Create parser for xml data
# tree = etree.fromstring(data.encode('utf-16-le'))
new_data = ''
for line in data.split('\n'):
    if re.search(r'</Modules>', line):
        new_data += xml_block.format(module_id=module_id, engine_name=engine_name)
    new_data += line

#print(new_data.replace('\r', '\n'))
# Write changes to file
try:
    f = codecs.open(ef_config, 'w', 'utf-16')
    f.write(new_data.replace('\r', '\n'))
except IOError, e:
    print e
finally:
    f.close()
