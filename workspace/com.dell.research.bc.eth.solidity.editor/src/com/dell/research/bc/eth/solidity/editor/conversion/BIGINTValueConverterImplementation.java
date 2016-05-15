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

import java.math.BigInteger;

import org.eclipse.xtext.conversion.IValueConverter;
import org.eclipse.xtext.conversion.ValueConverterException;
import org.eclipse.xtext.nodemodel.INode;

/**
 * This converter takes a string of digits and converts it to a BigInteger. This
 * is required because the default conversion converts the digits to an Integer
 * (too small).
 * 
 * see:
 * https://eclipse.org/Xtext/documentation/303_runtime_concepts.html#value-
 * converter
 */
public class BIGINTValueConverterImplementation implements IValueConverter<BigInteger> {

	@Override
	public BigInteger toValue(String string, INode node) throws ValueConverterException {
		return new BigInteger(string);
	}

	@Override
	public String toString(BigInteger value) throws ValueConverterException {
		return value.toString();
	}

}
