
CLASSPATH="diff-merge-1.5.1-SNAPSHOT-jar-with-dependencies.jar"
mkdir -p old

for file in new/*.xsd;
  do
    filename="${file##*/}"
    filename="${filename%%.*}"
    NEW="new/${filename}.xsd"
    OLD="old/${filename}.xsd"
    DIFF="diff/diff-${filename}.xml"
    echo Working on $filename...
    java io.fixprotocol.xml.XmlDiff $NEW $OLD $DIFF -u
    # Remove items that cannot be identical (also, -u cannot check elements without @id attribute)
    sed -i "" -e '/xmlns:dc/d' -e '/xmlns:fixr/d' -e '/diff/d' -e '/<?xml/d' $DIFF
    sed -i "" -e '/can be found/d' -e '/specification</d' $DIFF
    sed -i "" -e '/ImplicitBlock/d' -e '/Latest\.xsd/d' $DIFF
    sed -i "" -e '/attribute\[\@name=\&\#34\;s/d' -e '/EnumDoc\[/d' -e '/xs:enumeration\[/d' $DIFF
    [ -s $DIFF ] && echo ">>>File $NEW is different from $OLD"
done
