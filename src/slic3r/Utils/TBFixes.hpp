#pragma once

#include "libslic3r/PrintBase.hpp"

#include <cstddef>
#include <functional>
#include <map>
#include <string>
#include <vector>

namespace Slic3r {

class DynamicPrintConfig;
class Model;
class Print;
class SlicingErrors;

namespace TBFixes {

class FirstLayerRetry {
public:
    bool try_fix(const SlicingErrors &errors, Print &print, Model &model, const DynamicPrintConfig &config,
                 std::vector<PrintBase::SlicingStatus> &warnings, size_t warnings_before,
                 const std::function<void(const std::string &, size_t, double)> &record_adjustment);

private:
    std::map<size_t, double> m_lowered;
};

} // namespace TBFixes
} // namespace Slic3r
