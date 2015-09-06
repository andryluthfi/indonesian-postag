/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.File;
import java.io.IOException;
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 *
 * @author Andry Luthfi
 */
public class ParseRule {

    public static boolean isTrace;
    public static boolean isVerbose;
    public static boolean isDetail;

    public static void main(String[] arguments) throws ParserConfigurationException, SAXException, IOException, ParseRule.ParseException {
        Map<String, String> configurations = ParseRule.extractConfigurations(arguments);
        String fileName = configurations.containsKey("filename") ? configurations.get("filename") : "./resources/rule.xml";
        String inputName = configurations.containsKey("inputname") ? configurations.get("inputname") : "res--ambigous.txt";
        String outputName = configurations.containsKey("outputname") ? configurations.get("outputname") : "res--parserule.txt";
        isTrace = configurations.containsKey("trace") ? configurations.get("trace").equalsIgnoreCase("true") : false;
        isVerbose = configurations.containsKey("verbose") ? true : false;
        isDetail = isVerbose ? configurations.get("verbose").equalsIgnoreCase("detail") : false;
        logConsole("Memulai...");
        if(inputName != null) {
            Rules rules = ParseRule.parseRules(fileName);
            File fileInput = new File(inputName);
            File fileOutput = new File(outputName);
             logConsole("Membaca Berkas... " + inputName);
            if(fileInput.exists()) {
                logConsole(String.format("Berkas Terbaca ... [%s]\n", inputName));
                BufferedReader reader = new BufferedReader(new FileReader(fileInput));
                BufferedWriter  writer = new BufferedWriter (new FileWriter(fileOutput));
                String line = null;
                List<Case> cases = new ArrayList<Case>();
                while((line = reader.readLine()) != null) {
                    if(line.matches("^[\\d,]+")) {
                        Case ambigousCase = new Case(line.split(","), isTrace);
                        while((line = reader.readLine()) != null && !line.equals("")) {
                            ambigousCase.addToken(line);
                        }
                        cases.add(ambigousCase);
                    }
                }

                writer.newLine();
                for(Case ambigousCase : cases) {
                    int lastTotalUnresolved = 0;
                    while(lastTotalUnresolved != ambigousCase.getTotalUnresolved()) {
                        ambigousCase.resetCurrent();
                        lastTotalUnresolved = ambigousCase.getTotalUnresolved();
                        logDetail("[============ before\t: " + lastTotalUnresolved);
                        while(ambigousCase.hasNextAmbigous()) {
                            String tag = rules.trace(ambigousCase);
                            String output = ambigousCase.solutionOutput(tag);
                            ambigousCase.setCurrentToken(output);
                            logDetail(output);
                            ambigousCase.nextAmbigous();
                        }
                        logDetail("[============ after\t: " + ambigousCase.getTotalUnresolved());
                    }
                    writer.write(ambigousCase.toString());
                    logConsole(ambigousCase);
                }
                writer.flush();
                writer.close();
            }   
        } else {
            System.out.printf("Maaf terjadi kesalahan, berkas masukan dengan nama \"%s\" tidak dapat ditemukan\n", inputName);
        }
    }

    public static Rules parseRules(String fileName) throws ParserConfigurationException, SAXException, IOException, ParseRule.ParseException {
        File fileXML = new File(fileName);
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document document = builder.parse(fileXML);

        Element root = document.getDocumentElement();
        root.normalize();

        Rules rules = new Rules();
        if (root.getNodeName().equals("rules")) {
            NodeList nodeRules = root.getElementsByTagName("rule");
            int totalRules = nodeRules.getLength();
            for (int i = 0; i < totalRules; i++) {
                Element nodeRule = (Element) nodeRules.item(i);
                if (nodeRule.hasAttribute(StringValue.Tags.string) && nodeRule.hasAttribute(StringValue.ID.string)) {
                    String[] tags = nodeRule.getAttribute(StringValue.Tags.string).split("/");
                    NodeList nodePremises = nodeRule.getElementsByTagName("premise");
                    String ID = nodeRule.getAttribute(StringValue.ID.string);

                    Premises premises = new Premises(ID);
                    for (int j = 0; j < nodePremises.getLength(); j++) {
                        Element nodePremise = (Element) nodePremises.item(j);
                        //System.out.println(" j : " + j + " , " + nodePremise.getAttribute(StringValue.Grammar.string));
                        boolean isExistOutput = nodePremise.hasAttribute(StringValue.Output.string);
                        boolean isExistGrammar = nodePremise.hasAttribute(StringValue.Grammar.string);
                        String grammar = isExistGrammar ? nodePremise.getAttribute(StringValue.Grammar.string) : "--";
                        String output = isExistOutput ? nodePremise.getAttribute(StringValue.Output.string) : "--";
                        premises.addPremise(grammar, output);
                    }
                    rules.addRule(tags, premises);
                } else {
                    throw new ParseRule.ParseException("Tag rule harus memiliki atribut tags");
                }
            }

        } else {
            throw new ParseRule.ParseException("Tidak ada Tag rules pada bagian root document");
        }
        return rules;
    }

    public static void logConsole(Object object) {
        if(isVerbose) {
            System.out.println(object);
        }
    }

    public static void logDetail(Object object) {
        if(isVerbose && isDetail) {
            System.out.println(object);
        }
    }

    /**
     * Extract configurations on command/console calling
     *
     * @param arguments list of arguments
     * @return configurations on HashMap
     */
    public static Map<String, String> extractConfigurations(String[] arguments) {
        Pattern pattern = Pattern.compile("^--([\\w-]+)=(.+)$");
        Map<String, String> configurations = new HashMap<String, String>();
        for (String argument : arguments) {
            Matcher matcher = pattern.matcher(argument);
            if (matcher.find() && matcher.groupCount() == 2) {
                configurations.put(matcher.group(1), matcher.group(2));
            }
        }
        return configurations;
    }

    protected static class ParseException extends Exception {
        public ParseException(String message) {
            super("Maaf pastikan berkas rules memiliki struktur tag rule yang sesuai." + message);
        }
    }

    protected enum StringValue {

        Output("output"), Grammar("grammar"), Tags("tags"), ID("id");
        public String string;

        StringValue(String string) {
            this.string = string;
        }

        @Override
        public String toString() {
            return this.string;
        }
    }
}
