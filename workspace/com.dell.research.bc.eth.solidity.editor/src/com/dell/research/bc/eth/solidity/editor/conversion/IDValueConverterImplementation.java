/*******************************************************************************
 * Copyright (c) 2016 Keoja LLC and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Daniel Ford, Keoja LLC - initial API and implementation
 *******************************************************************************/

package com.dell.research.bc.eth.solidity.editor.conversion;

import org.eclipse.xtext.conversion.IValueConverter;
import org.eclipse.xtext.conversion.ValueConverterException;
import org.eclipse.xtext.nodemodel.INode;
/**
 * see: https://eclipse.org/Xtext/documentation/303_runtime_concepts.html#value-converter 
 */
public class IDValueConverterImplementation implements IValueConverter<String> {

	@Override
	public String toValue(String string, INode node) throws ValueConverterException {
		return string;
	}

	@Override
	public String toString(String value) throws ValueConverterException {
		return value;
	}

}
