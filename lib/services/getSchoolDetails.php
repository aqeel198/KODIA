<?php
/*******************************************************
 * getSchoolDetails.php
 * سكربت لاسترجاع اسم المدرسة ورابط الشعار (Logo URL)
 * بناءً على رمز المدرسة المرسل عبر GET.
 *******************************************************/

// تفعيل عرض الأخطاء في وضع التطوير (يُنصح بتعطيلها في بيئة الإنتاج)
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json; charset=UTF-8');

// استرجاع بيانات الاتصال بقاعدة البيانات من متغيرات البيئة
$servername = getenv('DB_HOST');
$port       = getenv('DB_PORT') ? (int)getenv('DB_PORT') : 3306;
$username   = getenv('DB_USER');
$password   = getenv('DB_PASSWORD');
$dbname     = getenv('DB_NAME');

// التحقق من توفر بيانات الاتصال
if (!$servername || !$username || !$password || !$dbname) {
    die(json_encode(["error" => "بيانات الاتصال غير متوفرة. يرجى التأكد من إعداد متغيرات البيئة."]));
}

// إنشاء الاتصال بقاعدة البيانات
$conn = new mysqli($servername, $username, $password, $dbname, $port);
if ($conn->connect_error) {
    die(json_encode(["error" => "فشل الاتصال بقاعدة البيانات: " . $conn->connect_error]));
}
$conn->set_charset("utf8mb4");

// استلام رمز المدرسة من متغير GET
$school_code = isset($_GET['school_code']) ? trim($_GET['school_code']) : '';

if (empty($school_code)) {
    die(json_encode(["error" => "يرجى تزويد رمز المدرسة (school_code)."]));
}

// تحضير الاستعلام لاسترجاع الاسم ورابط الشعار
$stmt = $conn->prepare("SELECT name, logo_url FROM schools WHERE school_code = ?");
if ($stmt === false) {
    die(json_encode(["error" => "خطأ في التحضير: " . $conn->error]));
}
$stmt->bind_param("s", $school_code);
$stmt->execute();
$stmt->bind_result($name, $logo_url);

// التحقق من نتيجة الاستعلام وإرجاع البيانات بصيغة JSON
if ($stmt->fetch()) {
    echo json_encode([
        "name"     => $name,
        "logo_url" => $logo_url
    ]);
} else {
    echo json_encode(["error" => "لم يتم العثور على مدرسة برمز: $school_code"]);
}

$stmt->close();
$conn->close();
?>
