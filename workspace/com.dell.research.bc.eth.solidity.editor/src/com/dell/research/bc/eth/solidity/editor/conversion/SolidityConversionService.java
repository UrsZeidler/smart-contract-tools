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
import org.eclipse.xtext.conversion.IValueConverterService;
import org.eclipse.xtext.conversion.ValueConverter;
import org.eclipse.xtext.conversion.impl.AbstractDeclarativeValueConverterService;

/**
 * see: https://eclipse.org/Xtext/documentation/303_runtime_concepts.html#value-
 * converter
 */
public class SolidityConversionService extends AbstractDeclarativeValueConverterService
		implements IValueConverterService {

	// The string "INT" is the same as the string used to identify
	// the terminal rule in Solidity.xtext
	@ValueConverter(rule = "INT")
	public IValueConverter<BigInteger> INT() {
		return new BIGINTValueConverterImplementation();
	}

	@ValueConverter(rule = "ID")
	public IValueConverter<String> ID() {
		return new IDValueConverterImplementation();
	}

	@ValueConverter(rule = "STRING")
	public IValueConverter<String> STRING() {
		return new STRINGValueConverterImplementation();
	}
}
