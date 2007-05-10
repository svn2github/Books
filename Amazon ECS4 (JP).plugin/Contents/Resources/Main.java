package net.aetherial.quickfill.amazon;

import java.io.*;
import java.net.*;
import java.util.*;

import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;

import org.w3c.dom.*;

public class Main 
{
	@SuppressWarnings("deprecation")
	public static void main (String[] args)
	{
		try 
		{
			DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance ();

			HashMap<String, String> paramMap = new HashMap<String, String> ();
			
			Document params = dbf.newDocumentBuilder().parse ("/tmp/books-quickfill.xml");
			NodeList nl = params.getElementsByTagName ("field");

			for (int i = 0; i < nl.getLength (); i++)
			{
				Element f = (Element) nl.item (i);
				
				paramMap.put (f.getAttribute ("name"), f.getTextContent ());
			}

			URL url = null; 

			if (paramMap.get ("isbn") != null && !paramMap.get ("isbn").equals (""))
			{
				url = new URL ("http://xml.amazon.co.jp/onca/xml?Service=AWSECommerceService&t=aetherialnu0a-20&" +
				   "AWSAccessKeyId=1M21AJ49MF6Y0DJ4D1G2&ResponseGroup=Large&Operation=ItemLookup&IdType=ASIN&" +
				   "ItemId=" + paramMap.get ("isbn"));
			}
			else
			{
				String powerQuery = "title:\"" + paramMap.get ("title") + "\"";

				if (paramMap.get ("authors") != null && !paramMap.get ("authors").equals (""))
					powerQuery += " and author:\"" + paramMap.get ("authors");
						
				url = new URL ("http://xml.amazon.co.jp/onca/xml?f=xml&Service=AWSECommerceService" +
					"&t=aetherialnu0a-20&AWSAccessKeyId=1M21AJ49MF6Y0DJ4D1G2&ResponseGroup=Large" + 
					"&Operation=ItemSearch&SearchIndex=Books&Power=" + URLEncoder.encode (powerQuery, "UTF-8"));
			}
			
			InputStream is = url.openStream ();
			
			Document d = dbf.newDocumentBuilder().parse (is);
			
			NodeList items = d.getElementsByTagName ("Item");
			
			ArrayList<HashMap<String, String>> itemList = new ArrayList<HashMap<String, String>> (); 
			
			Document output = dbf.newDocumentBuilder().parse (
								new StringBufferInputStream ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
															 "<importedData><List name=\"Amazon Import\" />" +
															 "</importedData>"));

			Element list = (Element) output.getElementsByTagName("List").item(0);
			
			for (int i = 0; i < items.getLength (); i++)
			{
				Element item = (Element) items.item (i);
				
				Element itemAttributes = (Element) item.getElementsByTagName ("ItemAttributes").item (0);

				HashMap<String, String> itemDef = new HashMap<String, String> ();
				
				NodeList fields = itemAttributes.getChildNodes ();
				
				for (int j = 0; j < fields.getLength (); j++)
				{
					Element f = (Element) fields.item (j);
				
					String name = f.getNodeName ();
					String value = f.getTextContent ();
					
					if (name.equals ("Author"))
						name = "authors";
					else if (name.equals ("Title"))
						name = "title";
					else if (name.equals ("Publisher"))
						name = "publisher";
					else if (name.equals ("PublicationDate"))
						name = "publishDate";
					else if (name.equals ("NumberOfPages"))
						name = "length";
					else if (name.equals ("ISBN"))
						name = "isbn";
					else if (name.equals ("Binding"))
						name = "format";
					
					String oldValue = itemDef.get (name);
					
					if (oldValue != null)
						value = oldValue + "; " + value;

					itemDef.put (name, value);
				}
				
				itemDef.put ("isbn", ((Element) item.getElementsByTagName ("ASIN").item (0)).getTextContent ());

				Element cover = (Element) item.getElementsByTagName ("LargeImage").item (0);
				
				if (cover == null)
				{
					cover = (Element) item.getElementsByTagName ("MediumImage").item (0);

					if (cover == null)
						cover = (Element) item.getElementsByTagName ("SmallImage").item (0);
				}
				
				if (cover != null)
					itemDef.put ("CoverImageURL", ((Element) cover.getElementsByTagName ("URL").item (0)).getTextContent ());
				
				itemList.add (itemDef);
			}
			
			for (int i = 0; i < itemList.size (); i++)
			{
				HashMap<String, String> itemDef = itemList.get (i);
				
				Element book = output.createElement ("Book");
				book.setAttribute ("title", itemDef.get("title"));
				
				Object[] keys = itemDef.keySet().toArray();
				for (int j = 0; j < keys.length; j++)
				{
					String key = (String) keys[j];
					String value = itemDef.get (key);

					Element f = output.createElement ("field");
					
					f.setAttribute ("name", key);
					f.setTextContent (value);

					book.appendChild (f);
				}
				
				list.appendChild (book);
			}
			
            DOMSource s = new DOMSource (output);
            
            // StreamResult result = new StreamResult (new FileOutputStream ("/Users/cjkarr/Desktop/result.xml"));
            StreamResult result = new StreamResult (System.out);
    
            Transformer xformer = TransformerFactory.newInstance ().newTransformer ();
            xformer.setOutputProperty (OutputKeys.INDENT, "yes");
            xformer.transform (s, result);
		} 
		catch (Exception e) 
		{
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
