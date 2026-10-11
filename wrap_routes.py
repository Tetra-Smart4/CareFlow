import re

file_path = r'lib\core\routing\app_router.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'package:careflow/screens/patient/queue/live_queue_screen.dart';", 
"import 'package:careflow/screens/patient/queue/live_queue_screen.dart';\nimport 'package:careflow/core/routing/auth_guard.dart';")

def replacer(match):
    route = match.group(1)
    widget_code = match.group(2).strip()
    
    if route.startswith('/splash') or route.startswith('/auth'):
        return match.group(0)
        
    roles = ""
    if route.startswith('/patient'):
        roles = "['patient']"
    elif route.startswith('/doctor'):
        roles = "['doctor']"
    elif route == '/admin/platform-dashboard':
        roles = "['platform_admin']"
    elif route.startswith('/admin'):
        roles = "['clinic']"
    elif route == '/clinic/pending':
        roles = "['clinic_pending']"
    elif route == '/clinic/rejected':
        roles = "['clinic_rejected']"
    elif route.startswith('/shared'):
        roles = "['patient', 'doctor', 'clinic', 'admin', 'staff', 'family', 'platform_admin']"
    elif route.startswith('/staff'):
        roles = "['staff']"
    elif route.startswith('/family'):
        roles = "['family']"
    else:
        return match.group(0)
        
    if 'AuthGuardWidget' in widget_code:
        return match.group(0)
        
    return f"'{route}': (_) => const AuthGuardWidget(allowedRoles: {roles}, child: {widget_code}),"

pattern = re.compile(r"'(/[^']+)': \(_\) =>\s*([^,]+),")
new_content = pattern.sub(replacer, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done")
