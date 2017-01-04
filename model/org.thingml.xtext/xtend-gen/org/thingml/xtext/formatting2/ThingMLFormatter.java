/**
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 */
/**
 * generated by Xtext 2.10.0
 */
package org.thingml.xtext.formatting2;

import com.google.inject.Inject;
import java.util.Arrays;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.formatting2.AbstractFormatter2;
import org.eclipse.xtext.formatting2.IFormattableDocument;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.xbase.lib.Extension;
import org.thingml.xtext.services.ThingMLGrammarAccess;
import org.thingml.xtext.thingML.Configuration;
import org.thingml.xtext.thingML.Import;
import org.thingml.xtext.thingML.PlatformAnnotation;
import org.thingml.xtext.thingML.PrimitiveType;
import org.thingml.xtext.thingML.Protocol;
import org.thingml.xtext.thingML.ThingMLModel;
import org.thingml.xtext.thingML.Type;

@SuppressWarnings("all")
public class ThingMLFormatter extends AbstractFormatter2 {
  @Inject
  @Extension
  private ThingMLGrammarAccess _thingMLGrammarAccess;
  
  protected void _format(final ThingMLModel thingMLModel, @Extension final IFormattableDocument document) {
    EList<Import> _imports = thingMLModel.getImports();
    for (final Import imports : _imports) {
      document.<Import>format(imports);
    }
    EList<Type> _types = thingMLModel.getTypes();
    for (final Type types : _types) {
      document.<Type>format(types);
    }
    EList<Protocol> _protocols = thingMLModel.getProtocols();
    for (final Protocol protocols : _protocols) {
      document.<Protocol>format(protocols);
    }
    EList<Configuration> _configs = thingMLModel.getConfigs();
    for (final Configuration configs : _configs) {
      document.<Configuration>format(configs);
    }
  }
  
  protected void _format(final PrimitiveType primitiveType, @Extension final IFormattableDocument document) {
    EList<PlatformAnnotation> _annotations = primitiveType.getAnnotations();
    for (final PlatformAnnotation annotations : _annotations) {
      document.<PlatformAnnotation>format(annotations);
    }
  }
  
  public void format(final Object primitiveType, final IFormattableDocument document) {
    if (primitiveType instanceof XtextResource) {
      _format((XtextResource)primitiveType, document);
      return;
    } else if (primitiveType instanceof PrimitiveType) {
      _format((PrimitiveType)primitiveType, document);
      return;
    } else if (primitiveType instanceof ThingMLModel) {
      _format((ThingMLModel)primitiveType, document);
      return;
    } else if (primitiveType instanceof EObject) {
      _format((EObject)primitiveType, document);
      return;
    } else if (primitiveType == null) {
      _format((Void)null, document);
      return;
    } else if (primitiveType != null) {
      _format(primitiveType, document);
      return;
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(primitiveType, document).toString());
    }
  }
}
