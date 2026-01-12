//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterDetailOverviewView.swift
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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI


// MARK: CharacterDetailOverviewView
struct CharacterDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: ExtendedCharacter
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeZone = .init(identifier: "Asia/Tokyo")!
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return df
    }
    var body: some View {
        CustomGroupBox(cornerRadius: 20) {
            VStack {
                Group {
                    // MARK: Info
                    Group {
                        // MARK: Name
                        Group {
                            ListItem(title: {
                                Text("Character.name")
                                    .bold()
                            }, value: {
                                MultilingualText(information.character.characterName)
                            })
                            Divider()
                        }
                        
                        if !(information.character.nickname.jp ?? "").isEmpty {
                            // MARK: Nickname
                            Group {
                                ListItem(title: {
                                    Text("Character.nickname")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.character.nickname)
                                })
                                Divider()
                            }
                        }
                        
                        if let profile = information.character.profile {
                            // MARK: Character Voice
                            Group {
                                ListItem(title: {
                                    Text("Character.character-voice")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.characterVoice)
                                })
                                Divider()
                            }
                        }
                        
                        if let color = information.character.color {
                            // MARK: Color
                            Group {
                                ListItem(title: {
                                    Text("Character.color")
                                        .bold()
                                }, value: {
                                    Text(color.toHex() ?? "")
                                        .fontDesign(.monospaced)
                                        .speechSpellsOutCharacters()
                                    RoundedRectangle(cornerRadius: 7)
                                    //                                    .aspectRatio(1, contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundStyle(color)
                                })
                                Divider()
                            }
                        }
                        
                        if let bandID = information.character.bandID {
                            // MARK: Band
                            Group {
                                ListItem(title: {
                                    Text("Character.band")
                                        .bold()
                                }, value: {
                                    Text(DoriCache.preCache.mainBands.first{$0.id == bandID}?.bandName.forPreferredLocale(allowsFallback: true) ?? "Unknown")
                                    WebImage(url: DoriCache.preCache.mainBands.first{$0.id == bandID}?.iconImageURL)
                                        .resizable()
                                        .interpolation(.high)
                                        .antialiased(true)
                                    //                                    .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    
                                })
                                Divider()
                            }
                        }
                        
                        if let profile = information.character.profile {
                            // MARK: Role
                            Group {
                                ListItem(title: {
                                    Text("Character.role")
                                        .bold()
                                }, value: {
                                    Text(profile.part.localizedString)
                                })
                                Divider()
                            }
                            
                            // MARK: Role
                            Group {
                                ListItem(title: {
                                    Text("Character.birthday")
                                        .bold()
                                }, value: {
                                    Text(dateFormatter.string(from: profile.birthday))
                                })
                                Divider()
                            }
                            
                            // MARK: Constellation
                            Group {
                                ListItem(title: {
                                    Text("Character.constellation")
                                        .bold()
                                }, value: {
                                    Text(profile.constellation.localizedString)
                                })
                                Divider()
                            }
                            
                            // MARK: Height
                            Group {
                                ListItem(title: {
                                    Text("Character.height")
                                        .bold()
                                }, value: {
                                    Text(Measurement(value: Double(profile.height), unit: UnitLength.centimeters), format: .measurement(width: .narrow, usage: .personHeight))
                                })
                                Divider()
                            }
                            
                            // MARK: School
                            Group {
                                ListItem(title: {
                                    Text("Character.school")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.school)
                                })
                                Divider()
                            }
                            
                            // MARK: Favorite Food
                            Group {
                                ListItem(title: {
                                    Text("Character.year-class")
                                        .bold()
                                }, value: {
                                    MultilingualText({
                                        var localizedContent = LocalizedData<String>()
                                        for locale in DoriLocale.allCases {
                                            localizedContent._set("\(profile.schoolYear.forLocale(locale) ?? String(localized: "Info.unknown")) - \(profile.schoolClass.forLocale(locale) ?? String(localized: "Info.unknown"))", forLocale: locale)
                                        }
                                        return localizedContent
                                    }())
                                })
                                Divider()
                            }
                            
                            // MARK: Favorite Food
                            Group {
                                ListItem(title: {
                                    Text("Character.favorite-food")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.favoriteFood)
                                })
                                Divider()
                            }
                            
                            // MARK: Disliked Food
                            Group {
                                ListItem(title: {
                                    Text("Character.disliked-food")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.hatedFood)
                                })
                                Divider()
                            }
                            
                            // MARK: Hobby
                            Group {
                                ListItem(title: {
                                    Text("Character.hobby")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.hobby)
                                })
                                Divider()
                            }
                            
                            // MARK: Introduction
                            Group {
                                ListItem(title: {
                                    Text("Character.introduction")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.selfIntroduction, showSecondaryText: false, allowPopover: false)
                                })
                                .listItemLayout(.basedOnUISizeClass)
                                Divider()
                            }
                        }
                        
                        
                        // MARK: ID
                        Group {
                            ListItem(title: {
                                Text("ID")
                                    .bold()
                            }, value: {
                                Text("\(String(information.id))")
                            })
                        }
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}
