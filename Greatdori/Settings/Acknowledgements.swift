//===---*- Greatdori! -*---------------------------------------------------===//
//
// Acknowledgements.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

struct AcknowledgementItem: Equatable, Hashable {
    var title: String
    var subtitle: String
    var licenseVerbatim: String
    
    fileprivate init(
        _ title: String,
        licenseName subtitle: String,
        content licenseVerbatim: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.licenseVerbatim = licenseVerbatim
    }
}

@resultBuilder
private struct AcknowledgementBuilder {
    static func buildExpression(_ expression: AcknowledgementItem) -> [AcknowledgementItem] {
        [expression]
    }
    
    static func buildBlock(_ components: [AcknowledgementItem]...) -> [AcknowledgementItem] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [AcknowledgementItem]?) -> [AcknowledgementItem] {
        component ?? []
    }
}

let packageAcknowledgements = _packageAcknowledgements()
let codeSnippetAcknowledgements = _codeSnippetAcknowledgements()

@AcknowledgementBuilder
private func _packageAcknowledgements() -> [AcknowledgementItem] {
    AcknowledgementItem(
        "Alamofire",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2014-2022",
            name: "Alamofire Software Foundation (http://alamofire.org/)"
        )
    )
    
    AcknowledgementItem(
        "cmark-gfm",
        licenseName: "BSD2 License",
        content: cmarkGfmLicense
    )
    
    AcknowledgementItem(
        "Cryptor",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "CryptorECC",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "CryptorRSA",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "EFQRCode",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2017-2025",
            name: "EyreFree <eyrefree@eyrefree.org>"
        )
    )
    
    AcknowledgementItem(
        "KituraContracts",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "LoggerAPI",
        licenseName: "Apache License 2.0 License",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "LRUCache",
        licenseName: "MIT License",
        content: "MIT License\n\n" + MIT_License(
            year: "2021",
            name: "Nick Lockwood"
        )
    )
    
    if !isMACOS {
        AcknowledgementItem(
            "Mute",
            licenseName: "MIT License",
            content: MIT_License(
                year: "2017",
                name: "Akram Hussein <akramhussein@gmail.com>"
            )
        )
    }
    
    AcknowledgementItem(
        "NetworkImage",
        licenseName: "MIT License",
        content: "MIT License\n\n" + MIT_License(
            year: "2020",
            name: "Guille Gonzalez"
        )
    )
    
    AcknowledgementItem(
        "SDWebImage",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2009-2020",
            name: "Olivier Poitrey rs@dailymotion.com"
        )
    )
    
    AcknowledgementItem(
        "SDWebImageSVGCoder",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2018",
            name: "lizhuoli1126@126.com <lizhuoli1126@126.com>"
        )
    )
    
    AcknowledgementItem(
        "SDWebImageSwiftUI",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2019",
            name: "lizhuoli1126@126.com <lizhuoli1126@126.com>"
        )
    )
    
    AcknowledgementItem(
        "swift_qrcodejs",
        licenseName: "MIT License",
        content: "MIT License\n\n" + MIT_License(
            year: "2017-2020",
            name: "Zhiyu Zhu/朱智语/ApolloZhu"
        )
    )
    
    AcknowledgementItem(
        "swift-argument-parser",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0 + swiftSuffix
    )
    
    AcknowledgementItem(
        "swift-atomics",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0 + swiftSuffix
    )
    
    AcknowledgementItem(
        "swift-gyb",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2018",
            name: "Read Evaluate Press, LLC"
        )
    )
    
    AcknowledgementItem(
        "swift-log",
        licenseName: "MIT License",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "swift-markdown-ui",
        licenseName: "MIT License",
        content: "The MIT License (MIT)\n\n" + MIT_License(
            year: "2020",
            name: "Guillermo Gonzalez"
        )
    )
    
    AcknowledgementItem(
        "swift-syntax",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0 + swiftSuffix
    )
    
    AcknowledgementItem(
        "SwiftDraw",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2019",
            name: "Simon Whitty"
        )
    )
    
    AcknowledgementItem(
        "SwiftJWT",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0
    )
    
    AcknowledgementItem(
        "SwiftSoup",
        licenseName: "MIT License",
        content: swiftSoupMITLicense
    )
    
    AcknowledgementItem(
        "swiftui-introspect",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2019",
            name: "Timber Software"
        )
    )
    
    AcknowledgementItem(
        "SwiftyJSON",
        licenseName: "MIT License",
        content: "The MIT License (MIT)\n\n" + MIT_License(
            year: "2017",
            name: "Ruoyu Fu"
        )
    )
    
    AcknowledgementItem(
        "SymbolAvailability",
        licenseName: "MIT License",
        content: "MIT License\n\n" + MIT_License(
            year: "2026",
            name: "WindowsMEMZ"
        )
    )
}

@AcknowledgementBuilder
private func _codeSnippetAcknowledgements() -> [AcknowledgementItem] {
    AcknowledgementItem(
        "gyb.py",
        licenseName: "Apache License 2.0",
        content: Apache_License_2_0 + swiftSuffix
    )
    
    AcknowledgementItem(
        "live2d.min.js",
        licenseName: "Live2D Proprietary Software 使用許諾契約書",
        content: Live2D_Proprietary_Software_License
    )
    
    AcknowledgementItem(
        "NSTextView-LineNumberView",
        licenseName: "MIT License",
        content: MIT_License(
            year: "2015",
            name: "Yichi Zhang"
        )
    )
}
                        
private func MIT_License(year: String, name: String) -> String {
    """
    Copyright (c) \(year) \(name)
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    """
}

private let Apache_License_2_0 = """
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
"""


private let cmarkGfmLicense = """
Copyright (c) 2014, John MacFarlane

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-----

houdini.h, houdini_href_e.c, houdini_html_e.c, houdini_html_u.c

derive from https://github.com/vmg/houdini (with some modifications)

Copyright (C) 2012 Vicent Martí

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-----

buffer.h, buffer.c, chunk.h

are derived from code (C) 2012 Github, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-----

utf8.c and utf8.c

are derived from utf8proc
(<http://www.public-software-group.org/utf8proc>),
(C) 2009 Public Software Group e. V., Berlin, Germany.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

-----

The normalization code in normalize.py was derived from the
markdowntest project, Copyright 2013 Karl Dubost:

The MIT License (MIT)

Copyright (c) 2013 Karl Dubost

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-----

The CommonMark spec (test/spec.txt) is

Copyright (C) 2014-15 John MacFarlane

Released under the Creative Commons CC-BY-SA 4.0 license:
<http://creativecommons.org/licenses/by-sa/4.0/>.

-----

The test software in test/ is

Copyright (c) 2014, John MacFarlane

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

private let swiftSuffix = """




## Runtime Library Exception to the Apache 2.0 License: ##


    As an exception, if you use this Software to compile your source code and
    portions of this Software are embedded into the binary product as a result,
    you may redistribute such product without providing attribution as would
    otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.
"""

private let Live2D_Proprietary_Software_License = """
Live2D Proprietary Software 使用許諾契約書

対象ソフトウェア

Live2D Cubism Core

Live2D Cubism MotionSync Core

本契約は、株式会社Live2D（以下、「Live2D社」といいます）と契約を締結されたお客様との間で、本ソフトウェア（以下に定義されています。）の使用許諾に関して定めるものです。

本契約へのリンクを含むボックスにチェックを入れる、「承諾」をクリックする、または本ソフトウェアをダウンロード、インストール、使用することにより、お客様は本契約を理解し、その条件にすべて合意したとみなされます。お客様は、本契約の全ての条項に同意しない場合、本ソフトウェアを使用できません。

お客様は、本契約の全部または一部を補足し、またはこれに優先して適用される別個の契約（例えば、ボリュームライセンス契約）を直接Live2D社と締結している場合があります。それにより、本ソフトウェアに含まれるか、または本ソフトウェアを通じてアクセスする一部のLive2D社の文書、ネットワーク資源、サンプル素材およびサービスの使用については、追加の条件が適用される場合があります。

1. 定義

1.1 「本ソフトウェア」とは、お客様に提供された上記対象ソフトウェアのプログラム、埋め込まれている独自のスクリプト記述、ソースコード、画像、ドキュメント、修正版、コピー、アップグレード、アップデートおよび追加情報のすべてを意味します。

1.2 「従業員等」とは、お客様およびお客様の法人または類似の企業体の役員、被雇用者（常勤、非常勤、有期雇用、無期雇用を問いません）、契約社員、派遣社員、アルバイトその他の法人等と委任または雇用契約があり、本ソフトウェアを取得した法人等の業務に従事する者を意味します。

1.3 「お客様」とは、本ソフトウェアのライセンス（本契約書第2条に規定されています。）を取得したお客様および当該お客様が所属する法人、ならびに当該お客様が所属する法人の従業員等を意味します。例えば、お客様の雇用主やお客様の従業員等がこれにあたります。

1.4 「派生作品」とは、本ソフトウェアの全てまたは一部を使用して制作されたアプリケーション、アニメーションタイトル等の作品などを意味します。

1.5 「拡張性アプリケーション」とは、大幅な拡張機能を有する派生作品を意味します。具体的には、ファイルやデータの追加や組み合わせ等によって不特定多数のモデルやデータを利用および生成する派生作品（例：アバター、配信アプリ、動画生成ツール）、単一タイトルの中に複数の作品や別の作品を内包しているもしくは単一タイトルを通じてこれらにアクセスできる派生作品（例：関連作品のコレクションやポータル）が含まれます。

1.6 「出版」とは、本ソフトウェアを使用して制作されたお客様の派生作品を個人的、内部的、営利、非営利またはその他のいかなる形であれ、頒布、譲渡、放送、宣伝、公開、共有等の方法で閲覧・利用可能にすることを意味します。出版に該当するか否かは、Live2D社が専らその裁量によって決定する権利を留保します。

1.7 「非営利」とは、自身（個人・法人その他の団体を含む。）の経済的利益を追求することを目的としない活動、および第三者を利することを目的としない活動を意味します。企業による活動、およびその依頼による、または、その利益のためにする活動は、たとえ活動の主体が個人や団体であっても非営利とは認められません。

1.8 「内部的」とは、特定の法人または類似の企業体においては従業員等のみ、および、特定の機関または団体においてはその構成員のみを対象とすることを意味します。

1.9 「トレーニング」とは、お客様が本ソフトウェアおよび本ソフトウェアを使用する互換コンピューターの取り扱いまたはその機能に習熟するための行為を意味します。

1.10 「出力ファイル」とは、お客様が本ソフトウェアを使用して作成する出力ファイルを意味します。

1.11 「エンドユーザー」とは、派生作品および出力ファイルを最終的に使用する個人または団体を意味します。

1.12 「配布」とは、有償であるか無償であるかを問わず、本ソフトウェア、ソースコード、オブジェクトコード（以下に定義されています。）の一部または全部、あるいは、派生作品および出力ファイルを含む、本ソフトウェアを使用して制作した出版物を、第三者が使用可能とすることを目的として、上演、上映、公衆送信、展示または頒布することおよびそれらの準備行為（インターネットを介してアクセスする第三者のために本ソフトウェアの一部または全部およびお客様の出版物をサーバーに導入することも含みます。）を意味します。

1.13 「配布者」とは、派生作品および出力ファイルを含む、本ソフトウェアを使用して制作した出版物を配布する行為をお客様の代理で行う個人または団体を意味します。

1.14 「再配布」とは、有償であるか無償であるかを問わず、入手した本ソフトウェアの一部または全部の複製物を、上演、上映、公衆送信、展示または頒布することおよびそれらの準備行為（インターネットを介してアクセスする第三者のために本マテリアルの一部または全部の複製物をサーバーに導入することも含みます。）を意味します。

1.15 「再配布可能コード」とは、本ソフトウェアに含まれる”RedistributableFiles.txt”ファイルに示された、および本契約書に添付された付録に示された、およびLive2D 社がお客様に別途指定するオブジェクトコード形式またはソースコード形式を意味します。

1.16 「ソースコード」とは、本ソフトウェアに含まれる、またはLive2D 社がお客様に別途指定する、人が読み取れる形式のソフトウェアのプログラムを意味します。これには、そのソフトウェアのプログラムに含まれているすべてのモジュール、関連するインターフェースの定義ファイル、コンパイルおよび実行可能ファイル（オブジェクトコード）のインストールを制御するために使用されるスクリプトが含まれます。

1.17 「オブジェクトコード」とは、本ソフトウェアに含まれる、またはLive2D 社がお客様に別途指定する、互換コンピューターが実行可能な形式のソフトウェアのプログラムを意味します。これには、そのソフトウェアのプログラムに含まれているすべてのモジュール、関連するライブラリファイル、ソースコードをコンパイルした結果であるバイナリコードを含む中間的なデータ表現のファイルが含まれます。

1.18 「互換コンピューター」とは、本ソフトウェアの使用に推奨されるオペレーティングシステムおよびハードウェア構成で使用されるコンピューター（以下に定義されています。）を意味します。

1.19 「コンピューター」とは、デジタルまたは類似の形式の情報を受け取り、それを一連の命令に基づいて処理し、特定の結果を出力する仮想または物理的な1台の機器を意味します（デスクトップコンピューター、ラップトップ、タブレット、モバイルデバイス、通信機器、インターネット接続機器、およびさまざまな生産性型アプリケーション、娯楽アプリケーション、または他のソフトウェアアプリケーションを実行できるハードウェア製品を含みますがこれらに限定されません）。

1.20 「会員資格」とは、Live2D社が提供するソフトウェアおよびサービスを利用するための条件を満たす会員としての地位およびこれに伴う権利義務の総称を指します。この条件は、Live2D社の単独裁量により随時変更される可能性があります。

1.21 「一般ユーザー」とは、直近会計年度（会計年度がない場合は過去1年間）の商業活動による売上高（以下「直近売上高」という。）が1,000万円未満の個人・学生・サークル・その他の団体を意味します。直近売上高が1,000万円以上の場合は、その形態・法人格の有無を問わず一般ユーザーとは認められません。

1.22 「小規模事業者」とは、直近売上高が1,000万円未満の事業者（個人、法人その他の商業活動を営む団体を含みます。）を意味します。

1.23 「中規模事業者」とは、直近売上高が1,000万円以上、1億円未満の事業者（個人、法人その他の商業活動を営む団体を含みます。）を意味します。

1.24 「大規模事業者」とは直近売上高が1億円以上の事業者（個人、法人その他の商業活動を営む団体を含みます。）を意味します。

1.25 小規模事業者、中規模事業者が、他企業が実質的に運営している事業者（以下に定義されています。）である場合、その事業者の事業規模は実質的に運営している企業の売上高によって決定されます。

他企業が単独で発行済株式総数、総株主の議決権または出資総額の過半数を占める事業者。

他企業が複数で発行済株式総数、総株主の議決権または出資総額の3分の2超を占める事業者。

役員総数の過半数を、他企業の役員または職員が兼務している事業者。

その他、他企業が実質的に運営していると認められる事業者。

1.26 「適格教育機関」とは、各国の法律で定められた学校法人及び公営の職業訓練施設のうち、学習者に対する授業練習、教育および研究の目的のみに本ソフトウェアを利用する機関が該当します。お客様が適格教育機関であるか否かについては、Live2D社が専らその裁量により判断し、決定することができます。

2. ソフトウェア使用の許諾と出版許諾契約

2.1 使用の許諾と出版権の除外

お客様が本契約の全ての条件に従うことを条件に、Live2D社は、派生作品を出版する目的に限り本ソフトウェアを使用する限定的、非独占的、サブライセンス不可、および譲渡不可の使用権（以下「本件ライセンス」といいます。）をお客様に供与します。

ただしお客様は、本条第2項に該当する場合を除き、内部的、営利、非営利またはその他のいかなる形であれ、Live2D社との個別の契約をしない限り、派生作品を出版することはできません。派生作品を出版する場合、お客様とLive2D社の間で別途「Live2D 出版許諾契約書」を締結する必要があります。Live2D社は、お客様が出版する当該派生作品について、本ソフトウェアの採用実績として媒体・形式を問わず公開する権利を留保します。「Live2D 出版許諾契約書」の申込はLive2D社のカスタマーサポートに直接お問い合わせください。Live2D社はその判断に基づき、特定のお客様に対して本契約を解除する権利を留保します。

なお、拡張性アプリケーションの出版には「Live2D出版許諾契約書」の締結のほかお客様の事前の申請とLive2D社の承認が必要であり、申請の承認はLive2D社の裁量に委ねられるものとします。また、拡張性アプリケーションのための「Live2D出版許諾契約書」の条件は一般的な派生作品を出版するための条件とは異なるものとなります。

2.2 一般ユーザー、小規模事業者および適格教育機関への出版許諾契約免除

Live2D社は、一般ユーザー、小規模事業者および適格教育機関に対し、本契約の全ての条件に従うことを条件に、前項の「Live2D 出版許諾契約書」の締結およびその契約料を免除することができます。ただし、お客様が適格な一般ユーザー、小規模事業者および適格教育機関と判断されない場合、本項に定める免除は直ちに取り消されます。一旦適格と判断されたとしても、後に不適格と判断される場合もあり、この場合も不適格と判断された時点で本項に定める免除は直ちに取り消されます。適格の判断についてはLive2D社が専らその裁量により行います。Live2D社は、決定に関する異議・申し立てを受け付けないほか、決定方法に関する情報提供や説明を行う義務を負いません。また、一般ユーザーおよび小規模事業者であっても、会計年度の途中での売上高が1000万円を超えた場合および会計年度がない場合は過去1年間の売上高が1000万円を超えた場合、翌々月末日までにその旨をLive2D社に通知するものとします。当該通知があった場合およびLive2D社が一般ユーザーおよび小規模事業者の一会計年度における売上高（会計年度がない場合は過去1年間の売上高）が1000万円を超えていることを証明できた場合、その一般ユーザーおよび小規模事業者は、売上高が1000万円を超えた月に遡ってLive2D社「Live2D出版許諾契約書」を締結するものとします。なお、一般ユーザーおよび小規模事業者は、Live2D社から要求された場合は、自らの売上高を計算するのに必要な資料を提出するものとします。また、適格教育機関における本ソフトウェアの利用目的は練習、教育および研究のみに限られており、これらの目的を超えて使用する場合は出版許諾契約免除の対象にはなりません。また、6.3項に定める規定により、拡張性アプリケーションの出版については、本項に定める免除の対象になりません。

2.3 事業規模に基づく契約料の決定

Live2D社が定める「Live2D出版許諾契約書」の契約料は、お客様の事業規模に基づいて決定されます。事業規模は直近の年間の売上高によって一般ユーザー、小規模事業者、中規模事業者、大規模事業者に分類されます。なお、1.25項に記載の通り、実質的に運営している企業が異なる場合、事業規模は実質的に運営している企業の年間の売上高によって決定されます。

2.4 特定のプロモーションを目的とした一時的な出版の出版許諾契約免除

中規模以上の事業者による、特定のプロモーションを目的とした一時的な出版の場合、前項の「Live2D 出版許諾契約書」の締結およびその契約料が免除される「Live2D著作物シンプルライセンスプラン」が適用される場合があります。当該プラン利用には、お客様の事前の申請とLive2D社の書面による承認が必要であり、申請の承認はLive2D社が専らその裁量により行います。

https://www.live2d.com/business/SLP

3. 本契約の適用範囲

3.1 お客様は、本ソフトウェアを第三者の互換コンピューターにインストールし、または、本ソフトウェアを第三者に使用させることはできません。お客様は、本ソフトウェアをインストールした互換コンピューターを第三者に使用させる場合、当該第三者に本項の規定を遵守させるものとし、かつ、その履行に責任を負うものとします。

3.2 お客様が、法人を代表して本契約を締結する場合、かかる法人およびその従業員等を本契約の条件で拘束せしめる権限を有していることを表明し、これを保証するものとします。

3.3 お客様は、本ソフトウェアの使用に際し、日本国内外の著作権法並びに著作者の権利及びこれに隣接する権利に関する諸条約その他知的財産権に関する全ての法令を遵守するものとします。

4. 知的財産権

4.1 本ソフトウェア、およびそのコピーについては、Live2D社が特許権、著作権等、一切の知的財産権を有します。本ソフトウェアの構造、構成およびソースコードは、Live2D社に帰属する機密情報です。本ソフトウェアの知的財産権は、日本およびその他の国の著作権法、ならびに国際条約の条項を含むがこれらに限定されない法律等によって保護されています。

本契約に明示的に規定される場合を除き、Live2D社は、本ソフトウェアの購入および本契約の締結により、お客様に対し本ソフトウェアの知的財産権の実施、利用等の許諾または譲渡をするものではありません。明確に付与されていないすべての権利はLive2D社に帰属します。なお、本ソフトウェアおよび本ソフトウェアに関連するならびに本ソフトウェアが参照するデータの中に第三者が知的財産権を保有するものが含まれる場合、お客様は当該知的財産権を侵害しないものとします。

4.2 お客様ご自身が開発、出版、販売した派生作品の著作権その他の知的財産権はお客様が保有しますが、それに含まれる本ソフトウェアおよび本ソフトウェアの特許権、著作権等、一切の知的財産権はLive2D社が保有しています。Live2D社はかかる権利を行使、保護、維持、擁護、強制、および保全するために、差し止め、衡平法上の救済、またはその他の類似の救済、さらにその他利用可能な救済を求めることができ、さらにそのような救済を得る権利をLive2D社が保有していることに、お客様は同意するものとします。

4.3 Cybernoids、Live2D、および本ソフトウェアに含まれる名前およびすべての関連するタイトルやロゴは日本および/またはその他の国におけるLive2D社の登録商標または商標です。その他の商標は、すべて、それぞれの所有者に帰属します。

5. 再配布可能コード

本ソフトウェアには、本契約書に記載されているとおり、派生作品や出力ファイルに含めて再配布可能なコードが含まれている場合があります。再配布可能なコードが含まれている場合、お客様は、本ソフトウェアを利用した派生作品や出力ファイルを、エンドユーザーが使用できるようにするための目的に限り、以下の条件の下で、再配布可能コードを複製および再配布することができます

5.1 使用及び再配布の権利

お客様は、再配布可能コードを複製および再配布することができます。さらに、お客様は、派生作品や出力ファイルの配布者に対して、お客様の派生作品や出力ファイルの一部として再配布可能コードの複製および再配布を許可することができます。

5.2 再配布の条件

お客様は、お客様が配布するあらゆる再配布可能コードにつき、以下に従わなければなりません。

5.2.1 お客様の派生作品や出力ファイルにおいて再配布可能コードを利用する重要かつ主要な機能を追加すること。

5.2.2 お客様の派生作品や出力ファイルの配布者およびエンドユーザーに、本契約と同等の再配布可能コードを保護する条項に同意させること。

5.2.3 お客様の派生作品や出力ファイルの配布または使用に関して生じた費用および第三者からの請求（弁護士報酬を含みます）について、Live2D社を免責、防御、および補償すること。

5.2.4 再配布可能コードがオブジェクトコード形式またはソースコード形式である場合に関わらず、Live2D社が提供した現状のまま再配布を行うこと。

5.3 再配布の制限

お客様は、以下を行うことはできません。

5.3.1 本契約第2条に規定する出版許諾契約を結ばずに、お客様が派生作品や出力ファイルの名前にLive2D社の商標を使用すること、ならびに派生作品や出力ファイルがLive2D社の作成、公認、推奨に係るものであると誤認させるような表示、示唆を行うこと。なお、Live2D社の商標の適切な使用方法については、「Live2Dのロゴとブランドについてのガイドライン」を参照ください。

https://www.live2d.jp/brand

5.3.2 再配布可能コードの一部に除外ライセンスが適用されることとなるような方法で再配布可能コードのソースコードを改変または配布すること。本項における「除外ライセンス」とは、使用、改変、または再配布の条件として、（ⅰ）コードがソースコード形式で公開または配布されていること、または（ⅱ）第三者がコードを改変できることを満たすライセンスを意味します。

6. 禁止事項

お客様は、本ソフトウェアを使用するにあたり、次の行為をしてはならないものとします。お客様は、法律に特段の定めのない限り、本ソフトウェアを本契約にて明示的に許可された方法でのみ使用できます。なお、Live2D社は、本契約においてお客様に明示的に付与または許諾されていないすべての権利を留保します。

6.1 改変等の禁止

本契約内で明示的に許可される場合を除き、お客様は、本ソフトウェアおよびそれに付随して提供されるマニュアル、ヘルプ等の関連資料を、使用、複製し、または本ソフトウェアに対する修正、移植、翻案、翻訳等の改変を加えることはできません。また、本ソフトウェアに含まれるライセンスに関する記載を改変・修正・削除することはできません。

6.2 配布・公開・同梱の禁止

本契約内で明示的に許可される場合を除き、お客様は、本ソフトウェアの全部または一部を配布・公開したり派生作品に同梱したりすることはできません。

6.3 無断 出版の禁止

2.2項に定める規定によって免除されている場合を除き、本ソフトウェアを使って開発した派生作品を、「Live2D 出版許諾契約書」の締結なく 出版することはできません。

6.4 リバース エンジニアリングの禁止

お客様は、本ソフトウェアのリバースエンジニアリング、逆コンパイルまたは逆アセンブルを行うなどして、本ソフトウェアのソースコードの解読を試みることはできません。

6.5 譲渡の禁止

本契約内で明示的に許可される場合を除き、お客様は、本ソフトウェアに関するお客様の権利を第三者に賃貸、リース、販売、サブライセンス、譲渡もしくは移転すること、または本ソフトウェアのいずれかの部分を他の個人もしくは法人の互換コンピューターにコピーさせることはできません。お客様が本ソフトウェアを使った業務を第三者に委託する場合、該当する第三者が直接Live2D社と本契約を締結する必要があります。

6.6 本契約に関する契約上の地位等の譲渡の禁止

本契約内で明示的に許可される場合を除き、お客様は、本契約に基づいてお客様に付与される契約上の地位、権利及び義務を、第三者に対して譲渡、移転し、又は引き受けさせることはできません。

6.7 代理使用請負サービスの禁止

お客様は、本件ライセンスを保有していない第三者に対して、出力業務等、本ソフトウェアの代理使用を業務内容とする請負サービス等を提供できません。

6.8 その他の禁止事項

派生作品、もしくは出力ファイルをLive2D社が開発したミドルウェアと競合するか、または競合する可能性のあるミドルウェア等と組み合わせて使用すること。

Live2D社によるものではないライセンスに従い本ソフトウェアや出力ファイルに含まれる本ソフトウェアの一部または全部のコードまたは内容をリリースすること。

本ソフトウェアの製品識別表示もしくは商標・著作権・所有権表示、説明文、記号、ラベル、または本契約を削除または改変等すること。

お客様が居住するか、または本ソフトウェアをインストールもしくは使用する国の法律上、違法な派生作品の開発または作品の制作、特に、刑法のわいせつ物頒布等の罪や、児童買春、児童ポルノに係る行為等の処罰及び児童の保護等に関する法律に規定の罪に該当するような派生作品の開発または出版・配布を行うために、本ソフトウェアを使用すること。

本ソフトウェアを用いて、他者の権利を侵害する、または侵害のおそれがある行為をすること。

想定する主たる用途として、2Dクリエイターの創造性を毀損するおそれのある派生作品の開発または出版・配布を行うために、本ソフトウェアを使用すること。

Live2D社の製品またはLive2D社が公認する製品のような誤解を招く利用をすること。

Live2D社による本ソフトウェア又はサービスの提供、若しくはその提供に要する機器、設備その他設備の管理運営を妨げる行為、又はLive2D社の信用を毀損する行為若しくはそのおそれのある行為をすること。

派生作品の対象となるプラットフォーム(例：iOS, Android, Sony PlayStation など)のガイドラインおよびライセンシー契約に違反すること。

マニュアル、ヘルプなど本ソフトウェアに付随して提供される資料の一部または全部を複製すること。

反社会的勢力（暴力団、総会屋、その他の反社会的な団体又は個人）であるか、もしくは過去にそうであったお客様、または反社会的勢力により実質的に事業活動が支配されていると認められるお客様が、本ソフトウェアを使用すること。

本契約に関連して不正または虚偽の申立を行う、両者の信頼関係を損ねるような行動・発言をする等の信義則に反する行為を行うこと。

その他、Live2D社が不適切と判断する行為を行うこと。

7. 秘密保持

Live2D社およびお客様は、事前に相手方の書面による同意を得た場合を除き、相手方から開示された情報、知り得た相手方の技術上および営業上の秘密、相手方から秘密である旨の指定を受けた情報（以下総称して、「秘密情報」という。）を、第三者に漏洩してはならないものとします。ただし、次の各号に掲げるものについては、この限りではありません。

7.1 相手方から知得する以前に取得していた情報

7.2 相手方から取得する以前に公知であったか、又は相手方から知得した後に自らの責によらずに公知となった情報

7.3 正当な権限を有する第三者から秘密保持の義務を負わず知得した情報

7.4 法令の定めに基づき、又は権限のある官公庁から要求された情報

8. 契約の解除等

8.1 契約の解除

Live2D社は、お客様が次の各号に該当した場合（お客様が法人その他の団体の場合、その役員及び従業員等を含みます。）、お客様に対する催告を行うことなく、直ちに本契約を解除することができるものとします。

8.1.1 「6.禁止事項」に規定される禁止行為を行った場合

8.1.2 お客様が本契約に定める条項に違反し、お客様に対して催告したにもかかわらず、合理的な期間内に当該違反が是正されなかった場合

8.1.3 Live2D社の他の顧客又は取引先その他の利益を不当に害した場合、又はLive2D社の信用、社会的名声若しく は地位を傷つけ、若しくはLive2D社の業務を妨害した場合

8.1.4 反社会的勢力（暴力団、総会屋、その他の反社会的な団体又は個人）であること若しくはあったことが判明した場合、 又は反社会的勢力と、目的の如何を問わず、資本関係、取引関係、人的関係等のあること若しくはあったことが判明した場合

8.1.5 監督官庁より営業の許可取消し、停止等の処分を受けた場合

8.1.6 支払停止若しくは支払不能の状態に陥った場合、又は手形若しくは小切手が不渡りとなった場合

8.1.7 第三者より差押え、仮差押え、仮処分若しくは競売の申立て、又は公租公課の滞納処分を受けた場合

8.1.8 破産手続開始、民事再生手続開始、会社更生手続開始、特別清算手続開始の申立てを受け、又は自ら申立てを行った場合

8.1.9 解散、会社分割、事業譲渡又は合併の決議をした場合

8.1.10 資産又は信用状態に重大な変化が生じ、本契約に基づく債務の履行が困難になるおそれがあると認められる場合

8.1.11 お客様が本契約の違反、又は本ソフトウェアに関する知的財産権の侵害により、Live2D社に損害を与えた場合

8.1.12 その他、前各号に準じる事由が生じた場合

8.2 前項各号のいずれかの事由に該当した場合、お客様は、Live2D社に対して負っている債務の一切について当然に期限の利益を失い、直ちにLive2D社に対して全ての債務の支払いを行わなければなりません。

8.3 本契約の解除がなされても、Live2D社は、お客様に対して有する損害賠償請求権の行使を妨げられません。

8.4 8.1項に定める規定により本契約が終了した場合、お客様は、本件ソフトウェアおよびその複製物、派生作品や出力ファイル、その他本ソフトウェアの使用により派生するものを直ちに廃棄しなくてはならないものとします。

9. 契約の変更

本契約は、Live2D社の独自の判断により、必要に応じて随時その内容を変更することができるものとします。なお、Live2D社は、本契約の内容を変更する場合には、その旨を事前にLive2D社のウェブページ等にて公表するものとし、変更した内容は、最新の改定日から効力を有するものとします。

10. 限定的保証

10.1 Live2D社は、お客様が本ソフトウェアを使用する目的につき関知せず、本ソフトウェアの性能、互換性、非侵害、エラーがないこと、または特定目的への適合性について、一切の保証をいたしません。Live2D社が明示している本ソフトウェアの性能・機能が、お客様の使用目的に合致しなかったとしても、Live2D社は、お客様に返金や代用品の提供を行う責任を負いません。

10.2 Live2D社は、本ソフトウェアの対象となるプラットフォーム(例：iOS, Android, Sony PlayStation など)に対する、完全な互換性を約束しません。お客様は、本ソフトウェアに関する機能や表現が対象となるプラットフォームで動作しない場合があり、対象プラットフォームに関する機能や表現が本ソフトウェアで動作しない場合があることを理解し、同意するものとします。

10.3 本ソフトウェアの想定していないエラー、不具合（バグ）、対象プラットフォームやデバイスとの互換性に関する問題が発見された場合、Live2D社は、必要に応じてその情報をお客様に開示するとともに、不具合等を合理的な範囲で修正します。ただし、情報提供または修正の必要性や時期についてはLive2D社が専らその裁量により決定することができます。

11. 責任の制限

法律上除外または制限することのできない救済手段を除き、Live2D社は、本ソフトウェアの使用から直接または間接的に生起した問題について、直接損害、拡大損害、派生損害、間接損害、付随的損害、利益の喪失、貯蓄の喪失、または事業の中断、傷害、注意義務違反もしくは第三者からの請求に基づくすべての損害を含むがこれらに限定されない一切の損失、損害、請求もしくは費用について、お客様に対して賠償する責を負わないものとします。いかなる場合においても、本契約に起因または関連して、Live2D社が負う責任の総額は、本ソフトウェアのライセンスの対価としてお客様が支払った金額を上限とします。

12. 損害賠償

お客様が、「6.禁止事項」に規定される禁止行為をし、又はその他本契約の各条項に違反した場合には、Live2D社は、これによりLive2D社が被った損害の賠償をお客様に請求できるものとします。Live2D社がお客様に対して法的措置を取ることを決定した場合、お客様がLive2D社の合理的な弁護士費用を負担するものとします。

13. プライバシー

13.1 Live2D社は、有効なライセンス、または会員資格に準拠しない不正な使用や不許可の使用を検出もしくは防止するためにお客様の情報を使用する場合があります。本ソフトウェアのアクティベーションまたは登録、または会員資格の確認を行わない場合、もしくは本ソフトウェアが不正にまたは許可を得ないで使用されたとLive2D社が判定した場合、本ソフトウェアの利用停止、機能制限あるいは停止等の措置を講じる場合があります。Live2D社は、本項に基づきLive2D社が行った措置につきお客様に生じた損害について一切の責任を負いません。

13.2 Live2D社の判断に基づき、本ソフトウェアに関連する告知や、または機能の一環として、お客様の登録アドレスに対して、メールを送信する場合があります。

13.3 Live2D社は、お客様からのサポートリクエストの内容や回答について、プライバシーや個人が特定できる情報を除いた形で、フォーラムやQ&A、FAQ等の一般に公開されている場所に転載する権利を留保します。

13.4 プライバシーに関してはLive2D社のプライバシーポリシーを参照ください。

14. フィードバックおよび貢献物

14.1 お客様からLive2D社に対してアイデア、フィードバック、提案、資料、情報、意見その他のインプット（以下「フィードバック」といいます。）が提供されても、説明文などの添付の有無を問わず、Live2D社はお客様のフィードバックを検討したり実施したりする義務はなく、かかるフィードバックは機密扱いとはなりません。Live2D社（その承継人や譲受人を含みます）は、お客様への報酬または帰属性なしに、かかるフィードバックを使用、複製、改変および開示する権利があり、お客様はフィードバックに対するいわゆる「人格権」を放棄し、これを主張しないことに合意します。

14.2 お客様が何らかの手段 (フォーラム、wiki、ソースコードリポジトリ、電子メール、ブログ等を含みますが、それらの方法に限られません。)を通じて本ソフトウェアに関するあらゆるプログラム(ソースコード形式、オブジェクトコード形式を問いません。)の全部または一部、その他の情報またはコンテンツ（以下「貢献物」といいます。）をLive2D社に対して提供した場合、お客様は、Live2D社に対し、かかる貢献物に含まれる著作権（著作権法第27条、28条に定める権利を含みます。）、特許権、その他一切の知的財産権を含むすべての権利、権限および利益（以下「貢献物に関する権利」といいます。) について、当該権利の半分の持分をLive2D社へ譲渡するものとします。ただし、Live2D社による利用が不可能な形態によって、お客様が本ソフトウェアとともに使用するプログラムまたはコンテンツ等は、本項に定める貢献物に該当しません。

14.3 前項に規定するお客様が保有する貢献物に関する権利の持分に関し、お客様は、Live2D社に対し、非独占的かつ無償の、取消不能、譲渡可能、サブライセンス可能なライセンスを付与するものとし、任意の国における現在および将来の方法ならびにあらゆる形態の実施のために、貢献物の複製、配布、公開、作成、利用、販売、貸与、譲渡の申出、輸入、改変、翻案その他貢献物に基づく派生的な作品の作成、その他貢献物に関するあらゆる利用をLive2D社が行うことに合意するものとします。また、お客様は、お客様以外のライセンシーに対し、お客様が保有する貢献物に関する権利の持分に基づく一切の権利の行使をしないことに同意するものとします。

14.4 前2項に規定する貢献物に関する権利において、法的に使用許諾が不可能な権利（著作者人格権を含みますがこれに限られません。）については、お客様は、Live2D社およびお客様以外のライセンシーに対し、一切の当該権利を行使しないことに同意するものとします。また、お客様は、お客様が提供した貢献物をLive2D社が利用する際、当該貢献物につきLive2D社単独の著作権表示をすることに同意するものとします。

14.5 お客様は、Live2D社に提供したフィードバックを自由に使用し続けることができるとともに、Live2D社による使用が可能になった貢献物を、本契約に準拠して使用し続けることができるものとします。お客様は、お客様が提供したフィードバックまたは貢献物をLive2D社が使用する義務がないことを了解し同意するものとします。

14.6 お客様は、お客様がLive2D社に提供するフィードバックまたは貢献物に関して、次のとおり、表明し保証するものとします。

14.6.1 お客様が提供するフィードバックまたは貢献物に関する権利は、お客様が所有し、または適法な権限を有するものであり、いかなる担保、使用許諾もしくは、いかなる種類の負担も存在しないこと。

14.6.2 お客様が提供するフィードバックまたは貢献物は、いかなる種類の第三者の権利（特許権、著作権その他の知的財産権を含みます。）を侵害することも、違反することもないこと。

15. 準拠法、管轄裁判所

15.1 本契約は日本法に準拠し、日本法に従って解釈されるものとします。

15.2 本契約は、日本語で締結され、日本語による解釈がいかなる言語による翻訳にも優先されるものとします。

15.3 本契約の解釈および履行に関して生じる一切の紛争の解決については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。

16. 残存条項

本契約の終了後においても、4.（知的財産権）、7.（秘密保持）、10.（限定的保証）、11.（責任の制限）、12.（損害賠償）、14.（フィードバックおよび貢献物）、15. （準拠法、管轄裁判所）および本項の規定については、引き続き効力を有するものとします。

17. 一般条項

本契約の一部が無効であり強制力を有しないものとされた場合においても、その他の有効な部分は影響を受けず、その条件に従って効力および強制力を維持します。Live2D社は、本契約を必要に応じて随時改定することができ、その場合、本契約書はウェブページ等に表示された後、そこに記載されている最新の改定日から効力を発するものとします。本契約書を解釈するにあたっては、本契約の日本語版を使用します。本契約はLive2D社およびお客様の本ソフトウェアに関する完全な合意であり、本ソフトウェアに関する本契約締結以前の表明、交渉、了解、通信連絡、広告のすべてに優先します。

18. 個別規定および例外

本条は、本ソフトウェアの一部製品およびコンポーネントに関する固有の規定および上記条項に関する一部例外を規定します。本条の規定が本契約の他の条項と矛盾する場合、本条がそれらの条項に優先するものとします。

18.1 プレリリース版ソフトウェアの補足条件

本ソフトウェアが正式リリース以前の製品またはアルファ版およびベータ版ソフトウェア（以下、「プレリリース版ソフトウェア」といいます）である場合は、本条が適用されます。プレリリース版ソフトウェアは、Live2D社から提供される最終製品に相当するものではなく、バグ、エラーおよびシステム障害等またはデータの損失につながるその他の不具合を含む可能性があります。別の契約書に基づいてお客様がプレリリース版ソフトウェアを受領した場合は、本ソフトウェアの使用は、同時にその契約書の適用も受けます。

18.1.1 プレリリース版ソフトウェアは、Live2D社から提供される最終製品に相当するものではなく、バグ、エラーおよびシステム障害等またはデータの損失につながるその他の不具合を含む可能性があります。

18.1.2 本契約とは異なる契約書あるいは利用規約に基づいてお客様がプレリリース版ソフトウェアおよびその使用を可能にするライセンスを受領した場合は、本ソフトウェアの使用は、同時にその契約書の適用も受けます。

以上

バージョン： 2.1

改定日： 2025 年2月3日
"""

private let swiftSoupMITLicense = """
The MIT License

Copyright (c) 2009-2025 Jonathan Hedley <https://jsoup.org/>  
Swift port copyright (c) 2016-2025 Nabil Chatbi  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
