/*******************************************************************************
 * Copyright (c) 2015 Dell Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Daniel Ford, Dell Corporation - initial API and implementation
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor.tests

import com.dell.research.bc.eth.solidity.editor.SolidityInjectorProvider
import com.dell.research.bc.eth.solidity.editor.solidity.Solidity
import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith

import static com.dell.research.bc.eth.solidity.editor.tests.TestConstants.*

@RunWith(typeof(XtextRunner))
@InjectWith(typeof(SolidityInjectorProvider))
class ImportDirectiveTest  extends AbsSolidityUnitTest {
    @Inject extension ParseHelper<Solidity>;
    @Inject extension ValidationTestHelper

    val VALID_IMPORT = '''
        import "«IMPORT_URL_1»" ;
    '''

    val VALID_IMPORT1 = '''
        import * as x from "«IMPORT_URL_1»" ;
    '''

    val VALID_IMPORT2 = '''
        import {a as b, c as d} from "«IMPORT_URL_1»" ;
    '''

    @Test
    def void givenValidImportDirective_thenNoErrors() {
        VALID_IMPORT.parse.assertNoErrors
        VALID_IMPORT1.parse.assertNoErrors
        VALID_IMPORT2.parse.assertNoErrors
    }

    @Test
    def void givenValidImportDirective_thenParsedURLIsCorrect() {
        Assert::assertEquals(IMPORT_URL_1, VALID_IMPORT.parse.importDirective.last.importURI);
    }
    
    @Test
    def void givenValidImportDirective1_thenParsedURLIsCorrect() {
        Assert::assertEquals(IMPORT_URL_1, VALID_IMPORT1.parse.importDirective.last.importURI);
    }
    
    @Test
    def void givenValidImportDirective1_thenParsedUnitAliasCorrect() {
        Assert::assertEquals("x", VALID_IMPORT1.parse.importDirective.last.unitAlias);
    }
    
    @Test
    def void givenValidImportDirective2_thenParsedURLIsCorrect() {
        Assert::assertEquals(IMPORT_URL_1, VALID_IMPORT2.parse.importDirective.last.importURI);
    }
    
    @Test
    def void givenValidImportDirective2_thenParsedSymbolAliasCorrect() {
        Assert::assertEquals(2, VALID_IMPORT2.parse.importDirective.last.symbolAliases.size);
        Assert::assertEquals("a", VALID_IMPORT2.parse.importDirective.last.symbolAliases.get(0).symbol);
        Assert::assertEquals("b", VALID_IMPORT2.parse.importDirective.last.symbolAliases.get(0).alias);
    }
    
} // ImportDirectiveTest
