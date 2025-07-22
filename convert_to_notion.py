#!/usr/bin/env python3
"""
Flutter App Design Document to Notion Converter
Converts Korean Flutter app design document to Notion-compatible markdown format
"""

import re
import os
from pathlib import Path
from typing import List, Dict, Tuple

class NotionConverter:
    def __init__(self):
        self.notion_content = []
        self.current_section = ""
        
    def convert_file(self, input_file: str, output_file: str = None) -> str:
        """Convert markdown file to Notion-compatible format"""
        if not output_file:
            output_file = input_file.replace('.md', '_notion.md')
            
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Process the content
        notion_content = self.process_content(content)
        
        # Write to output file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(notion_content)
            
        print(f"✅ Converted successfully!")
        print(f"📁 Input: {input_file}")
        print(f"📁 Output: {output_file}")
        print(f"📄 Ready to import into Notion!")
        
        return output_file
    
    def process_content(self, content: str) -> str:
        """Process markdown content for Notion compatibility"""
        lines = content.split('\n')
        processed_lines = []
        
        for i, line in enumerate(lines):
            processed_line = self.process_line(line, i, lines)
            processed_lines.append(processed_line)
            
        return '\n'.join(processed_lines)
    
    def process_line(self, line: str, index: int, all_lines: List[str]) -> str:
        """Process individual line with Notion-specific formatting"""
        
        # Convert headers to Notion format with emojis
        if line.startswith('#'):
            return self.convert_header(line)
            
        # Convert code blocks to Notion callouts when appropriate
        if line.startswith('```sql'):
            return self.convert_sql_block_start()
        elif line.startswith('```dart'):
            return self.convert_dart_block_start()
        elif line == '```' and self.in_code_block():
            return self.convert_code_block_end()
            
        # Convert UI/UX sections to callouts
        if "**UI/UX 구현 상세**" in line:
            return self.convert_uiux_section()
            
        # Convert database interaction sections
        if "**데이터베이스 상호작용**" in line:
            return self.convert_database_section()
            
        # Convert function sections to toggles
        if "**기능 및 로직**" in line:
            return self.convert_function_section()
            
        # Enhance list items with better formatting
        if line.strip().startswith('- **'):
            return self.convert_feature_list(line)
            
        # Convert BLoC structure to code callout
        if "**BLoC 구조**" in line:
            return self.convert_bloc_section()
            
        return line
    
    def convert_header(self, line: str) -> str:
        """Convert headers with appropriate emojis and formatting"""
        level = len(line.split()[0])
        text = line.lstrip('#').strip()
        
        # Add emojis based on content
        emoji_map = {
            '개요': '📱',
            '아키텍처': '🏗️',
            '화면별': '📋',
            '스플래시': '✨',
            '온보딩': '👋',
            '로그인': '🔐',
            '회원가입': '📝',
            '메인': '🏠',
            '홈': '🏠',
            '검색': '🔍',
            '샵': '🏪',
            '예약': '📅',
            '결제': '💳',
            '마이페이지': '👤',
            '포인트': '🎯',
            '추천인': '👥',
            '설정': '⚙️',
            '피드': '📱',
            '기술적': '🔧',
            '보안': '🔐',
            '배포': '🚀'
        }
        
        emoji = ''
        for key, value in emoji_map.items():
            if key in text:
                emoji = f"{value} "
                break
                
        return f"{'#' * level} {emoji}{text}"
    
    def convert_sql_block_start(self) -> str:
        """Convert SQL code block to Notion callout"""
        return "> 💾 **데이터베이스 쿼리**\n> ```sql"
    
    def convert_dart_block_start(self) -> str:
        """Convert Dart code block to Notion callout"""
        return "> 📱 **Flutter/Dart 코드**\n> ```dart"
    
    def convert_code_block_end(self) -> str:
        """End code block in callout"""
        return "> ```"
    
    def convert_uiux_section(self) -> str:
        """Convert UI/UX section to attractive callout"""
        return "\n> 🎨 **UI/UX 구현 상세**\n>"
    
    def convert_database_section(self) -> str:
        """Convert database section to callout"""
        return "\n> 💾 **데이터베이스 상호작용**\n>"
    
    def convert_function_section(self) -> str:
        """Convert function section to toggle format"""
        return "\n> ⚡ **기능 및 로직**\n>"
    
    def convert_feature_list(self, line: str) -> str:
        """Enhance feature list items with emojis"""
        # Extract the feature name
        match = re.match(r'^(\s*)- \*\*(.*?)\*\*:(.*)', line)
        if match:
            indent, feature, description = match.groups()
            
            # Add appropriate emojis
            feature_emojis = {
                '로고': '🎯',
                '슬로건': '💬',
                '로딩': '⏳',
                '배경': '🌈',
                '전환': '🔄',
                '슬라이드': '📱',
                '인디케이터': '📍',
                '버튼': '🔘',
                '이미지': '🖼️',
                '텍스트': '📝',
                '제스처': '👆',
                '소셜': '🔗',
                '카카오': '💛',
                '애플': '🍎',
                '구글': '🔵',
                '검색': '🔍',
                '필터': '🔽',
                '결과': '📊',
                '지도': '🗺️',
                '카드': '🃏',
                '리스트': '📋',
                '새로고침': '🔄',
                '무한': '♾️',
                '헤더': '🎯',
                '섹션': '📦',
                '캐러셀': '🎠',
                '그리드': '⚏',
                '즐겨찾기': '⭐',
                '배너': '🏷️'
            }
            
            emoji = ''
            for key, value in feature_emojis.items():
                if key in feature:
                    emoji = f"{value} "
                    break
                    
            return f"{indent}- {emoji}**{feature}**:{description}"
            
        return line
    
    def convert_bloc_section(self) -> str:
        """Convert BLoC section to code callout"""
        return "\n> 🏗️ **BLoC 아키텍처**\n>"
    
    def in_code_block(self) -> bool:
        """Check if currently in a code block (simplified)"""
        # This is a simplified check - in a real implementation you'd track state
        return True
    
    def add_notion_features(self, content: str) -> str:
        """Add Notion-specific features like dividers and callouts"""
        
        # Add horizontal dividers between major sections
        content = re.sub(r'\n---\n', '\n\n---\n\n', content)
        
        # Convert important notes to callouts
        content = re.sub(
            r'\*\*중요\*\*: (.*?)(?=\n)',
            r'> ⚠️ **중요**: \1',
            content
        )
        
        # Convert tips to info callouts
        content = re.sub(
            r'\*\*팁\*\*: (.*?)(?=\n)',
            r'> 💡 **팁**: \1',
            content
        )
        
        return content
    
    def create_table_of_contents(self, content: str) -> str:
        """Generate table of contents for Notion"""
        toc_lines = ["# 📚 목차\n"]
        
        # Extract headers
        headers = re.findall(r'^(#+)\s+(.*?)$', content, re.MULTILINE)
        
        for level_chars, title in headers:
            level = len(level_chars)
            indent = "  " * (level - 1)
            # Clean title of emojis for TOC
            clean_title = re.sub(r'[^\w\s가-힣]', '', title).strip()
            toc_lines.append(f"{indent}- {clean_title}")
            
        toc_lines.append("\n---\n")
        return '\n'.join(toc_lines) + '\n'

def create_notion_pages(input_file: str) -> List[str]:
    """Split large document into smaller Notion pages"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by major sections (## level headers)
    sections = re.split(r'\n(?=## )', content)
    output_files = []
    
    converter = NotionConverter()
    
    for i, section in enumerate(sections):
        if not section.strip():
            continue
            
        # Get section title for filename
        title_match = re.match(r'## (.+)', section)
        if title_match:
            title = title_match.group(1)
            # Clean title for filename
            clean_title = re.sub(r'[^\w\s가-힣]', '', title).strip()
            clean_title = clean_title.replace(' ', '_')
            filename = f"notion_page_{i:02d}_{clean_title}.md"
        else:
            filename = f"notion_page_{i:02d}.md"
        
        # Process section content
        processed_section = converter.process_content(section)
        processed_section = converter.add_notion_features(processed_section)
        
        # Add table of contents if it's a large section
        if len(processed_section.split('\n')) > 50:
            toc = converter.create_table_of_contents(processed_section)
            processed_section = toc + processed_section
        
        # Write section to file
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(processed_section)
        
        output_files.append(filename)
        print(f"📄 Created: {filename}")
    
    return output_files

def main():
    """Main conversion function"""
    print("🚀 에뷰리띵 플러터 앱 설계서 → Notion 변환기")
    print("=" * 50)
    
    input_file = "에뷰리띵_플러터_앱_화면_상세_설계서.md"
    
    if not os.path.exists(input_file):
        print(f"❌ 파일을 찾을 수 없습니다: {input_file}")
        return
    
    # Check file size
    file_size = os.path.getsize(input_file) / 1024  # KB
    print(f"📊 파일 크기: {file_size:.1f} KB")
    
    # Option 1: Single file conversion
    print("\n🔄 옵션 1: 단일 파일 변환")
    converter = NotionConverter()
    single_output = converter.convert_file(input_file)
    
    # Option 2: Split into multiple pages
    print("\n🔄 옵션 2: 여러 페이지로 분할")
    page_files = create_notion_pages(input_file)
    
    print(f"\n✅ 변환 완료!")
    print(f"📁 단일 파일: {single_output}")
    print(f"📚 페이지 파일들: {len(page_files)}개")
    
    print("\n📋 Notion 가져오기 방법:")
    print("1. Notion에서 새 페이지 생성")
    print("2. '가져오기' 또는 'Import' 클릭")
    print("3. 'Markdown' 선택")
    print("4. 변환된 .md 파일 업로드")
    print("5. 🎉 완료!")
    
    # Create import instructions file
    with open("notion_import_instructions.md", 'w', encoding='utf-8') as f:
        f.write("""# 🚀 Notion 가져오기 가이드

## 📂 변환된 파일들
- `에뷰리띵_플러터_앱_화면_상세_설계서_notion.md` - 전체 문서 (단일 파일)
- `notion_page_XX_*.md` - 섹션별 분할 파일들

## 📋 Notion 가져오기 단계

### 방법 1: 단일 페이지로 가져오기
1. Notion에서 새 페이지 생성
2. "/" 입력 후 "Import" 선택
3. "Markdown" 선택
4. `에뷰리띵_플러터_앱_화면_상세_설계서_notion.md` 업로드

### 방법 2: 여러 페이지로 가져오기 (권장)
1. Notion에서 상위 페이지 생성 ("에뷰리띵 플러터 앱 설계서")
2. 각 `notion_page_XX_*.md` 파일을 개별 하위 페이지로 가져오기
3. 페이지 구조 정리

## 🎨 Notion에서 추가 작업
- 페이지 아이콘 추가 (📱, 🏗️, 💾 등)
- 커버 이미지 설정
- 데이터베이스 뷰 생성 (필요 시)
- 팀원과 공유 설정

## 💡 팁
- 큰 파일은 분할된 버전 사용 권장
- 코드 블록은 Notion에서 자동으로 문법 강조됨
- 이모지와 아이콘이 자동으로 적용됨

""")
    
    print("📋 가져오기 가이드: notion_import_instructions.md")

if __name__ == "__main__":
    main() 