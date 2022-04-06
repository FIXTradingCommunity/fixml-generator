
# Usage: java io.fixprotocol.orchestra.fixml.FixmlGenerator <orchestra-file> <output-dir>
CLASSPATH="fixml-generator-1.4.2-SNAPSHOT-jar-with-dependencies.jar"
mkdir -p new
java io.fixprotocol.orchestra.fixml.FixmlGenerator orchestraEP269.xml new/
